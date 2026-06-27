import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:courto/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OtpPage extends StatefulWidget {
  final String phoneNumber;
  final String fullName;
  final String password;

  const OtpPage({
    super.key,
    required this.phoneNumber,
    required this.fullName,
    required this.password,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final List<TextEditingController> codeControllers =
      List.generate(4, (_) => TextEditingController());

  String? generatedCode;
  bool loading = false;
  int secondsRemaining = 0;
  Timer? timer;

  final apiUrl = dotenv.env['API_URL'];
  final rasaelUsername = dotenv.env['RASAEL_USERNAME'];
  final rasaelPassword = dotenv.env['RASAEL_PASSWORD'];

  bool get _isEnglish => Localizations.localeOf(context).languageCode == "en";
  TextDirection get _dir => _isEnglish ? TextDirection.ltr : TextDirection.rtl;

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
        body: json.encode({
          "username": rasaelUsername ?? "",
          "password": rasaelPassword ?? "",
        }),
      );

      if (loginRes.statusCode == 200) {
        final loginData = json.decode(loginRes.body);
        final token = loginData["token"]?.toString();

        if (token == null) {
          throw Exception(_isEnglish ? "Failed to get token" : "فشل الحصول على التوكن");
        }

        final smsRes = await http.post(
          Uri.parse("https://client.almasafa.ly/api/sms/Send"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: json.encode({
            "phoneNumber": widget.phoneNumber,
            "message": _isEnglish
                ? "Your verification code is: $generatedCode"
                : "رمز التحقق الخاص بك هو: $generatedCode",
            "senderID": "13201",
          }),
        );

        if (smsRes.statusCode != 200) {
          throw Exception(_isEnglish ? "Failed to send verification code" : "فشل إرسال رمز التحقق");
        }

        _startTimer();
      } else {
        throw Exception(_isEnglish
            ? "Failed to login to messaging service"
            : "فشل تسجيل الدخول لخدمة الرسائل");
      }
    } catch (e) {
      _showError("${_isEnglish ? "Error" : "خطأ"}: ${e.toString()}");
    } finally {
      if (mounted) setState(() => loading = false);
    }
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

  Future<void> _verifyCode() async {
    final enteredCode = codeControllers.map((c) => c.text).join();

    if (enteredCode != generatedCode) {
      _showError(_isEnglish ? "Invalid verification code" : "رمز التحقق غير صحيح");
      return;
    }

    setState(() => loading = true);

    try {
      final res = await http.post(
        Uri.parse("${apiUrl ?? ""}users/signup"),
        headers: {
          "Content-Type": "application/json",
          "x-api-key": dotenv.env['API_KEY'] ?? "",
        },
        body: json.encode({
          "full_name": widget.fullName,
          "phone_number": widget.phoneNumber,
          "password": widget.password,
        }),
      );

      if (!mounted) return;
      setState(() => loading = false);

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final message = data["message"] ??
            (_isEnglish ? "Account created successfully." : "تم انشاء الحساب بنجاح.");

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginPage(successMessage: message)),
          (route) => false,
        );
      } else {
        String message = _isEnglish ? "Failed to create account" : "فشل إنشاء الحساب";
        try {
          final data = json.decode(res.body);
          if (data["error"] != null) message = data["error"];
        } catch (_) {}

        Navigator.pop(context, message);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
      _showError(_isEnglish
          ? "An error occurred while creating the account"
          : "حدث خطأ أثناء إنشاء الحساب");
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, textDirection: _dir),
        backgroundColor: Theme.of(context).colorScheme.primary,
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
            textDirection: TextDirection.ltr, // digits are always LTR
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
    final isEnglish = _isEnglish;

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
                    isEnglish ? "Verification Code" : "رمز التحقق",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isEnglish
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
                              isEnglish ? "Confirm" : "تأكيد",
                              style: const TextStyle(fontSize: 16, color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: secondsRemaining > 0 ? null : _sendOtp,
                    child: Text(
                      secondsRemaining > 0
                          ? (isEnglish
                              ? "Resend in ${secondsRemaining}s"
                              : "إعادة الإرسال خلال ${secondsRemaining}ث")
                          : (isEnglish ? "Resend code" : "إعادة إرسال الرمز"),
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



// import 'dart:async';
// import 'dart:convert';
// import 'package:courto/pages/login_page.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:http/http.dart' as http;

// class OtpPage extends StatefulWidget {
//   final String phoneNumber;
//   final String fullName;
//   final String password;

//   const OtpPage({
//     super.key,
//     required this.phoneNumber,
//     required this.fullName,
//     required this.password,
//   });

//   @override
//   State<OtpPage> createState() => _OtpPageState();
// }

// class _OtpPageState extends State<OtpPage> {
//   final List<TextEditingController> codeControllers =
//       List.generate(4, (_) => TextEditingController());

//   bool loading = false;
//   int secondsRemaining = 0;
//   Timer? timer;

//   final apiUrl = dotenv.env['API_URL'] ?? "";

//   bool get _isEnglish => Localizations.localeOf(context).languageCode == "en";
//   TextDirection get _dir => _isEnglish ? TextDirection.ltr : TextDirection.rtl;

//   @override
//   void initState() {
//     super.initState();
//     _sendOtp();
//   }

//   @override
//   void dispose() {
//     timer?.cancel();
//     for (var c in codeControllers) {
//       c.dispose();
//     }
//     super.dispose();
//   }

//   // ── Ask backend to generate and send the OTP ────────────────────────────────
//   Future<void> _sendOtp() async {
//     setState(() {
//       loading = true;
//       secondsRemaining = 120;
//     });

//     try {
//       final res = await http.post(
//         Uri.parse("${apiUrl}users/send-otp"),
//         headers: {
//           "Content-Type": "application/json",
//           "x-api-key": dotenv.env['API_KEY'] ?? "",
//         },
//         body: json.encode({"phone_number": widget.phoneNumber}),
//       );

//       if (!mounted) return;

//       if (res.statusCode == 200) {
//         _startTimer();
//       } else {
//         // Show server's Arabic/English error message
//         final data = json.decode(res.body);
//         _showError(data["error"] ?? (_isEnglish ? "Failed to send code" : "فشل إرسال الرمز"));
//       }
//     } catch (_) {
//       _showError(_isEnglish ? "Connection error" : "خطأ في الاتصال");
//     } finally {
//       if (mounted) setState(() => loading = false);
//     }
//   }

//   void _startTimer() {
//     timer?.cancel();
//     timer = Timer.periodic(const Duration(seconds: 1), (t) {
//       if (secondsRemaining > 0) {
//         setState(() => secondsRemaining--);
//       } else {
//         t.cancel();
//       }
//     });
//   }

//   // ── Step 1: verify OTP with backend, Step 2: create account ────────────────
//   Future<void> _verifyCode() async {
//     final enteredCode = codeControllers.map((c) => c.text).join();

//     if (enteredCode.length < 4) {
//       _showError(_isEnglish ? "Please enter the full code" : "يرجى إدخال الرمز كاملاً");
//       return;
//     }

//     setState(() => loading = true);

//     try {
//       // ── Step 1: verify OTP ────────────────────────────────────────────────
//       final verifyRes = await http.post(
//         Uri.parse("${apiUrl}users/verify-otp"),
//         headers: {
//           "Content-Type": "application/json",
//           "x-api-key": dotenv.env['API_KEY'] ?? "",
//         },
//         body: json.encode({
//           "phone_number": widget.phoneNumber,
//           "code": enteredCode,
//         }),
//       );

//       if (!mounted) return;

//       if (verifyRes.statusCode != 200) {
//         final data = json.decode(verifyRes.body);
//         setState(() => loading = false);
//         _showError(data["error"] ?? (_isEnglish ? "Invalid code" : "رمز غير صحيح"));
//         return;
//       }

//       // ── Step 2: create account ────────────────────────────────────────────
//       final signupRes = await http.post(
//         Uri.parse("${apiUrl}users/signup"),
//         headers: {
//           "Content-Type": "application/json",
//           "x-api-key": dotenv.env['API_KEY'] ?? "",
//         },
//         body: json.encode({
//           "full_name": widget.fullName,
//           "phone_number": widget.phoneNumber,
//           "password": widget.password,
//         }),
//       );

//       if (!mounted) return;
//       setState(() => loading = false);

//       if (signupRes.statusCode == 200) {
//         final data = json.decode(signupRes.body);
//         final message = data["message"] ??
//             (_isEnglish ? "Account created successfully." : "تم إنشاء الحساب بنجاح.");

//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (_) => LoginPage(successMessage: message)),
//           (route) => false,
//         );
//       } else {
//         String message = _isEnglish ? "Failed to create account" : "فشل إنشاء الحساب";
//         try {
//           final data = json.decode(signupRes.body);
//           if (data["error"] != null) message = data["error"];
//         } catch (_) {}
//         Navigator.pop(context, message);
//       }
//     } catch (_) {
//       if (!mounted) return;
//       setState(() => loading = false);
//       _showError(_isEnglish
//           ? "An error occurred while creating the account"
//           : "حدث خطأ أثناء إنشاء الحساب");
//     }
//   }

//   void _showError(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message, textDirection: _dir),
//         backgroundColor: Theme.of(context).colorScheme.primary,
//       ),
//     );
//   }

//   Widget _otpFields() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: List.generate(4, (i) {
//         return SizedBox(
//           width: 55,
//           child: TextField(
//             controller: codeControllers[i],
//             keyboardType: TextInputType.number,
//             maxLength: 1,
//             textAlign: TextAlign.center,
//             textDirection: TextDirection.ltr,
//             style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             decoration: InputDecoration(
//               counterText: "",
//               filled: true,
//               fillColor: Theme.of(context).colorScheme.onPrimary,
//               contentPadding: const EdgeInsets.all(12),
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(5),
//               ),
//             ),
//             onChanged: (val) {
//               if (val.isNotEmpty && i < 3) {
//                 FocusScope.of(context).nextFocus();
//               }
//             },
//           ),
//         );
//       }),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final isEnglish = _isEnglish;

//     return Directionality(
//       textDirection: TextDirection.ltr,
//       child: Scaffold(
//         backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//         appBar: AppBar(
//           iconTheme: const IconThemeData(color: Colors.white),
//           backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
//         ),
//         body: SafeArea(
//           child: Center(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(24.0),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     isEnglish ? "Verification Code" : "رمز التحقق",
//                     style: TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                       color: Theme.of(context).colorScheme.primary,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     isEnglish
//                         ? "We sent a verification code to ${widget.phoneNumber}"
//                         : "تم إرسال رمز التحقق إلى ${widget.phoneNumber}",
//                     style: TextStyle(
//                       fontSize: 16,
//                       color: Theme.of(context).colorScheme.onSecondary,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 28),
//                   _otpFields(),
//                   const SizedBox(height: 28),
//                   SizedBox(
//                     width: double.infinity,
//                     height: 48,
//                     child: ElevatedButton(
//                       onPressed: loading ? null : _verifyCode,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Theme.of(context).colorScheme.primary,
//                         disabledBackgroundColor:
//                             Theme.of(context).colorScheme.primary,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(5),
//                         ),
//                       ),
//                       child: loading
//                           ? SizedBox(
//                               width: 20,
//                               height: 20,
//                               child: CircularProgressIndicator(
//                                 color: Theme.of(context).colorScheme.onPrimary,
//                                 strokeWidth: 2.5,
//                               ),
//                             )
//                           : Text(
//                               isEnglish ? "Confirm" : "تأكيد",
//                               style: const TextStyle(
//                                   fontSize: 16, color: Colors.white),
//                             ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   TextButton(
//                     onPressed: secondsRemaining > 0 ? null : _sendOtp,
//                     child: Text(
//                       secondsRemaining > 0
//                           ? (isEnglish
//                               ? "Resend in ${secondsRemaining}s"
//                               : "إعادة الإرسال خلال ${secondsRemaining}ث")
//                           : (isEnglish ? "Resend code" : "إعادة إرسال الرمز"),
//                       style: TextStyle(
//                         color: secondsRemaining > 0
//                             ? Colors.grey
//                             : Theme.of(context).colorScheme.primary,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }