import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;


class ResetPasswordPage extends StatefulWidget {
  final String phoneNumber;

  const ResetPasswordPage({super.key, required this.phoneNumber});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final newPassController = TextEditingController();
  final confirmPassController = TextEditingController();
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool loading = false;
  final apiUrl = dotenv.env['API_URL'];

  void _resetPassword() async {
    String newPass = newPassController.text.trim();
    String confirmPass = confirmPassController.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      _showError("يرجى ملء جميع الحقول");
      return;
    }

    if (newPass != confirmPass) {
      _showError("كلمتا المرور غير متطابقتين");
      return;
    }

    setState(() => loading = true);

    try {
      final res = await http.patch(
        Uri.parse("${apiUrl}users/resetPassword"),
        headers: {"Content-Type": "application/json", 'x-api-key': '${dotenv.env['API_KEY']}'},
        body: json.encode({
          "phone_number": widget.phoneNumber,
          "new_password": newPass,
        }),
      );

      setState(() => loading = false);

      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم تحديث كلمة المرور بنجاح"),
            backgroundColor: Colors.red,
          ),
        );
        // Pop all pages until LoginPage
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        String message = "فشل تحديث كلمة المرور";
        try {
          final data = json.decode(res.body);
          if (data["error"] != null) message = data["error"];
        } catch (_) {}
        _showError(message);
      }
    } catch (_) {
      setState(() => loading = false);
      _showError("حدث خطأ أثناء تحديث كلمة المرور");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textDirection: TextDirection.rtl),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    newPassController.dispose();
    confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.red[50],
        appBar: AppBar(
          backgroundColor: Colors.red,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Page Title
                const Text(
                  "إعادة تعيين كلمة المرور",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                // New Password
                TextField(
                  controller: newPassController,
                  obscureText: !showPassword,
                  decoration: InputDecoration(
                    labelText: "كلمة المرور الجديدة",
                    prefixIcon: const Icon(Icons.lock, color: Colors.red),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() => showPassword = !showPassword);
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextField(
                  controller: confirmPassController,
                  obscureText: !showConfirmPassword,
                  decoration: InputDecoration(
                    labelText: "تأكيد كلمة المرور الجديدة",
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.red),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() => showConfirmPassword = !showConfirmPassword);
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: loading ? null : _resetPassword,
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
                            "تحديث كلمة المرور",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
