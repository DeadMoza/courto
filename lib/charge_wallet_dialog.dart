import 'package:flutter/material.dart';
import 'services/auth_service.dart' show AuthService;

Future<void> showChargeWalletDialog(BuildContext context) async {
  if (!AuthService.isLoggedIn) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("يجب تسجيل الدخول أولاً")),
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
                          // Bank Card Button
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
                          // Courto Card Button
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedMethod = "courto"; // show input field
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
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final cardNumber = courtoCardController.text;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  "تم شحن المحفظة برقم بطاقة كورتو: $cardNumber"),
                            ),
                          );
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
