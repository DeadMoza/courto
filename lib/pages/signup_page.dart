import 'package:flutter/material.dart';
import 'otp_page.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  final String? errorMessage; // optional error passed back

  const SignupPage({super.key, this.errorMessage});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final passController = TextEditingController();
  final confirmPassController = TextEditingController();
  bool loading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    if (widget.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showError(widget.errorMessage!);
      });
    }
  }

  void _goToOtp() async {
    FocusScope.of(context).unfocus();

    // check empty fields
    if (nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        passController.text.trim().isEmpty ||
        confirmPassController.text.trim().isEmpty) {
      _showError("الرجاء ملء جميع الحقول");
      return;
    }

    // check password match
    if (passController.text != confirmPassController.text) {
      _showError("كلمتا المرور غير متطابقتين");
      return;
    }

    // Normalize phone number
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

    // Validate phone number format
    if (phone.length != 12 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      _showError("الرجاء إدخال رقم هاتف صحيح يبدأ بـ 2189");
      return;
    }
  

    final error = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpPage(
          phoneNumber: phone,
          fullName: nameController.text.trim(),
          password: passController.text.trim(),
        ),
      ),
    );

    if (error != null && error is String) {
      _showError(error);
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
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.red[50],
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images/courtoFull.png",
                    width: 150,
                    height: 150,
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    "إنشاء حساب",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Full Name
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "الاسم الكامل",
                      prefixIcon: const Icon(Icons.person, color: Colors.red),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: "رقم الهاتف",
                      prefixIcon: const Icon(Icons.phone, color: Colors.red),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextField(
                    controller: passController,
                    textAlign: TextAlign.right, 
                    textDirection: TextDirection.ltr,
                    obscureText: !showPassword,
                    decoration: InputDecoration(
                      labelText: "كلمة المرور",
                      prefixIcon: const Icon(Icons.lock, color: Colors.red),
                      suffixIcon: IconButton(
                        icon: Icon(
                          showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
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
                    textAlign: TextAlign.right, 
                    textDirection: TextDirection.ltr,
                    obscureText: !showConfirmPassword,
                    decoration: InputDecoration(
                      labelText: "تأكيد كلمة المرور",
                      prefixIcon:
                          const Icon(Icons.lock_outline, color: Colors.red),
                      suffixIcon: IconButton(
                        icon: Icon(
                          showConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() =>
                              showConfirmPassword = !showConfirmPassword);
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

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: loading ? null : _goToOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        disabledBackgroundColor: Colors.red[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: const Text(
                        "متابعة",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Switch to login
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: const Text(
                      "لديك حساب من قبل؟ تسجيل الدخول",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
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
