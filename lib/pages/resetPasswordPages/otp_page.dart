import 'dart:async';
import 'dart:convert';
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

  bool loading = false;
  int secondsRemaining = 0;
  Timer? timer;

  final apiUrl = dotenv.env['API_URL'];

  bool get _isEnglish => Localizations.localeOf(context).languageCode == "en";
  TextDirection get _dir => _isEnglish ? TextDirection.ltr : TextDirection.rtl;

  Map<String, String> get _headers => {
    "Content-Type": "application/json",
    "x-api-key": dotenv.env['API_KEY'] ?? "",
  };

  @override
  void initState() {
    super.initState();
    // Deferred a frame so the locale is readable when building the request.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sendOtp();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    for (var c in codeControllers) {
      c.dispose();
    }
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

  Future<void> _sendOtp() async {
    setState(() {
      loading = true;
      secondsRemaining = 120; // 2 minutes
    });

    try {
      final res = await http.post(
        Uri.parse("${apiUrl ?? ""}users/sendOtp"),
        headers: _headers,
        body: json.encode({
          "phone_number": widget.phoneNumber,
          "purpose": "reset",
          "lang": _isEnglish ? "en" : "ar",
        }),
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        _startTimer();
      } else {
        setState(() => secondsRemaining = 0);
        _showSnack(
          _serverError(res, _isEnglish ? "Failed to send code" : "فشل إرسال رمز التحقق"),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => secondsRemaining = 0);
      _showSnack(_isEnglish ? "Connection error" : "خطأ في الاتصال");
    }

    if (mounted) setState(() => loading = false);
  }

  String _serverError(http.Response res, String fallback) {
    try {
      final data = json.decode(res.body);
      return data["error"]?.toString() ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  void _startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (secondsRemaining > 0) {
        setState(() => secondsRemaining--);
      } else {
        t.cancel();
      }
    });
  }

  Future<void> _verifyCode() async {
    final enteredCode = codeControllers.map((c) => c.text).join();

    if (enteredCode.length < 4) {
      _showSnack(_isEnglish ? "Please enter the full code" : "يرجى إدخال الرمز كاملاً");
      return;
    }

    setState(() => loading = true);

    try {
      final res = await http.post(
        Uri.parse("${apiUrl ?? ""}users/verifyOtp"),
        headers: _headers,
        body: json.encode({
          "phone_number": widget.phoneNumber,
          "code": enteredCode,
          "purpose": "reset",
        }),
      );

      if (!mounted) return;
      setState(() => loading = false);

      if (res.statusCode != 200) {
        _showSnack(
          _serverError(res, _isEnglish ? "Incorrect code" : "رمز التحقق غير صحيح"),
        );
        return;
      }

      // The reset token proves this OTP step happened; the next page can't
      // change the password without it.
      final resetToken = (json.decode(res.body))["reset_token"]?.toString();

      if (resetToken == null) {
        _showSnack(_isEnglish ? "Verification failed" : "فشل التحقق");
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordPage(
            phoneNumber: widget.phoneNumber,
            resetToken: resetToken,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      _showSnack(_isEnglish ? "Connection error" : "خطأ في الاتصال");
    }
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
              fillColor: Theme.of(context).colorScheme.onPrimary,
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
    // Keep OTP inputs LTR always
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isEnglish ? "Verification Code" : "رمز التحقق",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isEnglish
                        ? "We sent a verification code to ${widget.phoneNumber}"
                        : "تم إرسال رمز التحقق إلى ${widget.phoneNumber}",
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
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
                              _isEnglish ? "Confirm" : "تأكيد",
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: secondsRemaining > 0 ? null : _sendOtp,
                    child: Text(
                      secondsRemaining > 0
                          ? (_isEnglish
                              ? "Resend in ${secondsRemaining}s"
                              : "إعادة الإرسال خلال ${secondsRemaining}ث")
                          : (_isEnglish ? "Resend code" : "إعادة إرسال الرمز"),
                      style: TextStyle(
                        color: secondsRemaining > 0
                            ? Colors.grey
                            : Theme.of(context).colorScheme.primary,
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
