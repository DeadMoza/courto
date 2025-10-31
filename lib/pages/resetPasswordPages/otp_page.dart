import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'reset_password_page.dart';

class OtpPage extends StatefulWidget {
  final String phoneNumber;

  const OtpPage({
    super.key,
    required this.phoneNumber,
  });

  @override
  OtpPageState createState() => OtpPageState();
}

class OtpPageState extends State<OtpPage> {
  final List<TextEditingController> codeControllers =
      List.generate(4, (_) => TextEditingController());
  String? generatedCode;
  bool loading = false;
  int secondsRemaining = 0;
  Timer? timer;
  final rasaelUsername = dotenv.env['RASAEL_USERNAME'];
  final rasaelPassword = dotenv.env['RASAEL_PASSWORD'];

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  @override
  void dispose() {
    timer?.cancel();
    for (var c in codeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() {
      loading = true;
      secondsRemaining = 120; // 2 minutes
    });

    generatedCode = (1000 + Random().nextInt(9000)).toString();

    try {
      final loginRes = await http.post(
        Uri.parse("https://client.almasafa.ly/api/MasafaRasaelLogin"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"username": "$rasaelUsername", "password": "$rasaelPassword"}),
      );

      if (loginRes.statusCode == 200) {
        final loginData = json.decode(loginRes.body);
        final token = loginData["token"]?.toString();

        if (token == null) throw Exception("فشل الحصول على التوكن");

        final smsRes = await http.post(
          Uri.parse("https://client.almasafa.ly/api/sms/Send"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: json.encode({
            "phoneNumber": widget.phoneNumber,
            "message": "رمز إعادة تعيين كلمة المرور هو: $generatedCode",
            "senderID": "13201",
          }),
        );

        if (smsRes.statusCode != 200) {
          throw Exception("فشل إرسال رمز التحقق");
        }

        _startTimer();
      } else {
        throw Exception("فشل تسجيل الدخول لخدمة الرسائل");
      }
    } catch (e) {
      _showError("خطأ: ${e.toString()}");
    }

    setState(() => loading = false);
  }

  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (secondsRemaining > 0) {
        setState(() => secondsRemaining--);
      } else {
        t.cancel();
      }
    });
  }

  void _verifyCode() {
    final enteredCode = codeControllers.map((c) => c.text).join();
    if (enteredCode != generatedCode) {
      _showError("رمز التحقق غير صحيح");
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResetPasswordPage(phoneNumber: widget.phoneNumber),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textDirection: TextDirection.rtl),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _otpFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (i) {
        return SizedBox(
          width: 55,
          child: TextField(
            controller: codeControllers[i],
            keyboardType: TextInputType.number,
            maxLength: 1,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: "",
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            onChanged: (val) {
              if (val.isNotEmpty && i < 3) {
                FocusScope.of(context).nextFocus();
              }
            },
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.red[50],
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Colors.red,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "رمز التحقق",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "تم إرسال رمز التحقق إلى ${widget.phoneNumber}",
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  _otpFields(),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: loading ? null : _verifyCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        disabledBackgroundColor: Colors.red[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              "تأكيد",
                              style: TextStyle(
                                  fontSize: 16, color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: secondsRemaining > 0 ? null : _sendOtp,
                    child: Text(
                      secondsRemaining > 0
                          ? "إعادة الإرسال خلال ${secondsRemaining}ث"
                          : "إعادة إرسال الرمز",
                      style: TextStyle(
                        color: secondsRemaining > 0 ? Colors.grey : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
