import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ResetPasswordPage extends StatefulWidget {
  final String phoneNumber;
  final String resetToken;

  const ResetPasswordPage({
    super.key,
    required this.phoneNumber,
    required this.resetToken,
  });

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

  bool get _isEnglish => Localizations.localeOf(context).languageCode == "en";
  TextDirection get _dir => _isEnglish ? TextDirection.ltr : TextDirection.rtl;

  void _resetPassword() async {
    String newPass = newPassController.text.trim();
    String confirmPass = confirmPassController.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      _showError(_isEnglish ? "Please fill all fields" : "يرجى ملء جميع الحقول");
      return;
    }

    if (newPass != confirmPass) {
      _showError(_isEnglish ? "Passwords do not match" : "كلمتا المرور غير متطابقتين");
      return;
    }

    setState(() => loading = true);

    try {
      final res = await http.patch(
        Uri.parse("${apiUrl}users/resetPassword"),
        headers: {
          "Content-Type": "application/json",
          'x-api-key': '${dotenv.env['API_KEY']}',
        },
        body: json.encode({
          "phone_number": widget.phoneNumber,
          "new_password": newPass,
          "reset_token": widget.resetToken,
        }),
      );

      if (!mounted) return;
      setState(() => loading = false);

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEnglish ? "Password updated successfully" : "تم تحديث كلمة المرور بنجاح",
              textDirection: _dir,
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );

        // Pop all pages until the first route (usually Login)
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        String message = _isEnglish ? "Failed to update password" : "فشل تحديث كلمة المرور";
        try {
          final data = json.decode(res.body);
          if (data["error"] != null) message = data["error"];
        } catch (_) {}
        _showError(message);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      _showError(_isEnglish
          ? "Network error while updating password"
          : "حدث خطأ أثناء تحديث كلمة المرور");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textDirection: _dir),
        backgroundColor: Theme.of(context).colorScheme.primary,
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
      textDirection: _dir,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          leading: IconButton(
            icon: Icon(
              _isEnglish ? Icons.arrow_back : Icons.arrow_back,
              color: Colors.white,
            ),
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

                Text(
                  _isEnglish ? "Reset Password" : "إعادة تعيين كلمة المرور",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                // New Password
                TextField(
                  controller: newPassController,
                  obscureText: !showPassword,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: _isEnglish ? "New password" : "كلمة المرور الجديدة",
                    prefixIcon: Icon(Icons.lock, color: Theme.of(context).colorScheme.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() => showPassword = !showPassword),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.onPrimary,
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
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: _isEnglish ? "Confirm new password" : "تأكيد كلمة المرور الجديدة",
                    prefixIcon: Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() => showConfirmPassword = !showConfirmPassword),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.onPrimary,
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
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      disabledBackgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: loading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.onPrimary,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            _isEnglish ? "Update password" : "تحديث كلمة المرور",
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
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
