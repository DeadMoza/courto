import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'otp_page.dart';

class PhoneInputPage extends StatefulWidget {
  final String? phoneNumber;

  const PhoneInputPage({super.key, this.phoneNumber});

  @override
  State<PhoneInputPage> createState() => _PhoneInputPageState();
}

class _PhoneInputPageState extends State<PhoneInputPage> {
  late TextEditingController phoneController;
  bool loading = false;
  final apiUrl = dotenv.env['API_URL'];

  bool get _isEnglish => Localizations.localeOf(context).languageCode == "en";
  TextDirection get _dir => _isEnglish ? TextDirection.ltr : TextDirection.rtl;

  @override
  void initState() {
    super.initState();
    phoneController = TextEditingController(text: widget.phoneNumber ?? "");
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textDirection: _dir),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  String _normalizeLibyanPhone(String input) {
    String phone = input.trim();

    if (phone.startsWith("09")) {
      phone = "218${phone.substring(1)}";
    } else if (phone.startsWith("9")) {
      phone = "218$phone";
    } else if (phone.startsWith("0")) {
      phone = "218${phone.substring(1)}";
    } else if (!phone.startsWith("218")) {
      phone = "218$phone";
    }

    return phone;
  }

  Future<void> _submitPhone() async {
    final raw = phoneController.text;
    final phone = _normalizeLibyanPhone(raw);

    if (raw.trim().isEmpty) {
      _showSnack(_isEnglish ? "Please enter your phone number" : "يرجى إدخال رقم الهاتف");
      return;
    }

    setState(() => loading = true);

    try {
      final url = Uri.parse("${apiUrl}users/checkPhoneNumber");
      final res = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          'x-api-key': '${dotenv.env['API_KEY']}',
        },
        body: jsonEncode({"phone_number": phone}),
      );

      if (!mounted) return;
      setState(() => loading = false);

      if (res.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpPage(phoneNumber: phone),
          ),
        );
      } else {
        String msg = _isEnglish ? "Failed to verify the number" : "فشل التحقق من الرقم";
        try {
          final data = jsonDecode(res.body);
          if (data["error"] != null) msg = data["error"].toString();
        } catch (_) {}
        _showSnack(msg);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      _showSnack(_isEnglish ? "Network error, please try again" : "خطأ في الاتصال بالشبكة");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _dir,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                _isEnglish ? "Reset Password" : "إعادة تعيين كلمة المرور",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                _isEnglish
                    ? "Enter the phone number registered with us to reset your password:"
                    : "أدخل رقم الهاتف المسجل لدينا لإعادة تعيين كلمة المرور:",
                style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr, // numbers always better LTR
                decoration: InputDecoration(
                  labelText: _isEnglish ? "Phone number" : "رقم الهاتف",
                  prefixIcon: Icon(Icons.phone, color: Theme.of(context).colorScheme.primary),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.onPrimary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: loading ? null : _submitPhone,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    disabledBackgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: loading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : Text(
                          _isEnglish ? "Continue" : "متابعة",
                          style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onPrimary),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
