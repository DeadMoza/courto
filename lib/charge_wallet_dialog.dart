import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';
import 'services/auth_service.dart' show AuthService;

Future<void> showChargeWalletDialog(BuildContext context) async {
  if (!AuthService.isLoggedIn) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("يجب تسجيل الدخول أولاً"), backgroundColor: Colors.redAccent),
    );
    return;
  }

  String? selectedMethod; // initially null
  final courtoCardController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text(
              "شحن المحفظة",
              textAlign: TextAlign.center,
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SizeTransition(
                      sizeFactor: animation,
                      axisAlignment: -1.0,
                      child: child,
                    ),
                  );
                },
                child: selectedMethod == "courto"
                    ? Padding(
                        key: const ValueKey('courtoForm'),
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Form(
                          key: _formKey,
                          child: TextFormField(
                            controller: courtoCardController,
                            keyboardType: TextInputType.number,
                            maxLength: 13,
                            decoration: InputDecoration(
                              labelText: "أدخل رقم الكرت",
                              prefixIcon: const Icon(
                                Icons.card_membership,
                                color: Colors.red,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.length != 13) {
                                return "يجب أن يكون 13 رقماً";
                              }
                              if (!RegExp(r'^\d{13}$').hasMatch(val)) {
                                return "يجب يحتوي على أرقام فقط";
                              }
                              return null;
                            },
                          ),
                        ),
                      )
                    : Row(
                        key: const ValueKey("buttonsRow"),
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () {
                              // TODO: implement bank card flow
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.red[100],
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: const Icon(
                                    Icons.credit_card,
                                    size: 40,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text("بطاقة مصرفية"),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedMethod = "courto"; 
                              });
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.red[100],
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: const Icon(
                                    Icons.card_membership,
                                    size: 40,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text("كرت كورتو"),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            actions: selectedMethod == "courto"
                ? [
                    TextButton(
                      child: const Text("إلغاء"),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    ElevatedButton(
                      child: const Text("تأكيد"),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final cardNumber = courtoCardController.text;
                          Navigator.pop(ctx); // close dialog before showing loader

                          // Show loading overlay that blocks user interaction
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(
                              child: CircularProgressIndicator(color: Colors.redAccent),
                            ),
                          );

                          try {
                            final response = await http.post(
                              Uri.parse("${apiUrl}users/redeemVoucher"),
                              headers: {
                                'Content-Type': 'application/json',
                                'authorization': 'Bearer ${AuthService.token}'
                              },
                              body: jsonEncode({
                                'code': cardNumber,
                                'user_id': AuthService.userData?["id"],
                              }),
                            );

                            Navigator.pop(context); // close the loading dialog

                            final data = jsonDecode(response.body);

                            if (data['success'] == true) {
                              // Update wallet balance locally
                              AuthService.userData?['wallet_balance'] = data['wallet_balance'];

                              // Save updated user data in SharedPreferences
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('userData', jsonEncode(AuthService.userData));

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "تم شحن المحفظة بمبلغ ${data['voucher_value']} دينار. "
                                    "الرصيد الحالي: ${data['wallet_balance']} دينار.",
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );

                              // Optional: refresh global UI state
                              setState(() {});
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(data['message'] ?? "حدث خطأ"),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          } catch (e) {
                            Navigator.pop(context); // ensure loader closes on error
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("حدث خطأ أثناء الاتصال بالخادم. يرجى المحاولة لاحقًا."),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      },

                    ),
                  ]
                : [
                    TextButton(
                      child: const Text("إلغاء"),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
          );
        },
      );
    },
  );
}
