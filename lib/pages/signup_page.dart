import 'package:flutter/material.dart';
import 'otp_page.dart';
import 'login_page.dart';
import 'package:flutter/gestures.dart';
import 'package:courto/l10n/app_localizations.dart';

class SignupPage extends StatefulWidget {
  final String? errorMessage;

  const SignupPage({super.key, this.errorMessage});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final passController = TextEditingController();
  final confirmPassController = TextEditingController();

  bool loading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  bool get _isEnglish => Localizations.localeOf(context).languageCode == "en";
  TextDirection get _dir => _isEnglish ? TextDirection.ltr : TextDirection.rtl;

  @override
  void initState() {
    super.initState();
    if (widget.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showError(widget.errorMessage!);
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    passController.dispose();
    confirmPassController.dispose();
    super.dispose();
  }

  void _goToOtp() async {
    FocusScope.of(context).unfocus();

    if (nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        passController.text.trim().isEmpty ||
        confirmPassController.text.trim().isEmpty) {
      _showError(_isEnglish ? "Please fill all fields" : "الرجاء ملء جميع الحقول");
      return;
    }

    String name = nameController.text.trim();

    if (!_isEnglish) {
      final arabicNameRegex = RegExp(r'^[\u0600-\u06FF\s]+$');
      if (!arabicNameRegex.hasMatch(name) || !name.contains(' ')) {
        _showError("الرجاء إدخال اسم كامل باللغة العربية");
        return;
      }
    } else {
      if (!name.contains(' ')) {
        _showError("Please enter your full name");
        return;
      }
    }

    String password = passController.text;
if (password.length < 8) {
  _showError(_isEnglish
      ? "Password must be at least 8 characters"
      : "كلمة المرور يجب أن تكون 8 أحرف على الأقل");
  return;
}

    if (passController.text != confirmPassController.text) {
      _showError(_isEnglish ? "Passwords do not match" : "كلمتا المرور غير متطابقتين");
      return;
    }

    String phone = phoneController.text.trim();
    if (phone.startsWith("09")) {
      phone = "218${phone.substring(1)}";
    } else if (phone.startsWith("9")) {
      phone = "218$phone";
    } else if (phone.startsWith("0")) {
      phone = "218${phone.substring(1)}";
    } else if (!phone.startsWith("218")) {
      phone = "218$phone";
    }

    if (!RegExp(r'^2189[0-9]{8}$').hasMatch(phone)) {
      _showError(_isEnglish
          ? "Please enter a valid Libyan phone number starting with 2189"
          : "الرجاء إدخال رقم هاتف صحيح يبدأ بـ 2189");
      return;
    }

    final error = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpPage(
          phoneNumber: phone,
          fullName: name,
          password: password,
        ),
      ),
    );

    if (!mounted) return;
    if (error != null && error is String) {
      _showError(error);
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

  void _showTermsDialog() {
    final t = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: _dir,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          title: Text(
            _isEnglish ? "Terms of Use" : "شروط الاستخدام",
            textDirection: _dir,
          ),
          content: SingleChildScrollView(
            child: Text(

              t.policyBody,
              textDirection: _dir,
              style: const TextStyle(height: 1.5, fontFamily: "Changa"),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_isEnglish ? "Close" : "إغلاق"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEnglish = _isEnglish;

    return Directionality(
      textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images/courtoFull.png",
                    width: 150,
                    height: 150,
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: nameController,
                    textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
                    decoration: InputDecoration(
                      labelText: isEnglish ? "Full Name" : "الاسم الكامل",
                      prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.onPrimary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    textAlign: TextAlign.left,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: isEnglish ? "Phone Number" : "رقم الهاتف",
                      prefixIcon: Icon(Icons.phone, color: Theme.of(context).colorScheme.primary),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.onPrimary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: passController,
                    textAlign: TextAlign.left,
                    textDirection: TextDirection.ltr,
                    obscureText: !showPassword,
                    decoration: InputDecoration(
                      labelText: isEnglish ? "Password" : "كلمة المرور",
                      prefixIcon: Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary),
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

                  TextField(
                    controller: confirmPassController,
                    textAlign: TextAlign.left,
                    textDirection: TextDirection.ltr,
                    obscureText: !showConfirmPassword,
                    decoration: InputDecoration(
                      labelText: isEnglish ? "Confirm Password" : "تأكيد كلمة المرور",
                      prefixIcon: Icon(Icons.lock, color: Theme.of(context).colorScheme.primary),
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
                  const SizedBox(height: 16),

                  RichText(
                    textAlign: TextAlign.center,
                    textDirection: isEnglish ? TextDirection.ltr : TextDirection.rtl,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSecondary,
                        fontFamily: "Changa",
                      ),
                      children: [
                        TextSpan(
                          text: isEnglish
                              ? "By creating an account, you agree to the "
                              : "بإنشاء حساب، فإنك توافق على ",
                        ),
                        TextSpan(
                          text: isEnglish ? "Terms of Use" : "شروط الاستخدام",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()..onTap = _showTermsDialog,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: loading ? null : _goToOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        disabledBackgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: Text(
                        isEnglish ? "Continue" : "متابعة",
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: Text(
                      isEnglish
                          ? "Already have an account? Log in"
                          : "لديك حساب من قبل؟ تسجيل الدخول",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      textDirection: _dir,
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
