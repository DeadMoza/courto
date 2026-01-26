import 'dart:convert';
import 'package:courto/payment_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'services/auth_service.dart' show AuthService;

Future<void> showChargeWalletDialog(BuildContext context) async {
  if (!AuthService.isLoggedIn) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("يجب تسجيل الدخول أولاً"),
        backgroundColor: Colors.redAccent,
      ),
    );
    return;
  }

  String? selectedMethod; // "courto" or "bank"
  final courtoCardController = TextEditingController();
  final amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final apiUrl = dotenv.env['API_URL'];

  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          // AnimatedSwitcher content
          Widget content = AnimatedSwitcher(
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
                            color: Colors.redAccent,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.onPrimary,
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
                : selectedMethod == "bank"
                    ? Padding(
                        key: const ValueKey('bankForm'),
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Form(
                          key: _formKey,
                          child: TextFormField(
                            controller: amountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "ادخل المبلغ",
                              prefixIcon: const Icon(
                                Icons.credit_card,
                                color: Colors.redAccent,
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.onPrimary,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(5),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return "الرجاء إدخال المبلغ";
                              }
                              final amount = int.tryParse(val);
                              if (amount == null || amount <= 0) {
                                return "مبلغ غير صالح";
                              }
                              if (amount > 200) {
                                return "الحد الأقصى 200 دينار";
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
                            onTap: () => setState(() => selectedMethod = "bank"),
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
                            onTap: () => setState(() => selectedMethod = "courto"),
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
                                    color: Colors.redAccent,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text("كرت كورتو"),
                              ],
                            ),
                          ),
                        ],
                      ),
          );

          return AlertDialog(
            title: const Text(
              "شحن المحفظة",
              textAlign: TextAlign.center,
            ),
            content: SizedBox(width: double.maxFinite, child: content),
            actions: selectedMethod == "courto"
                ? [
                    TextButton(
                      child: const Text("إلغاء"),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    ElevatedButton(
                      child: const Text("تأكيد"),
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;

                        showDialog(
                          context: ctx,
                          barrierDismissible: false,
                          builder: (_) => const Center(
                            child: CircularProgressIndicator(
                              color: Colors.redAccent,
                            ),
                          ),
                        );

                        try {
                          final response = await http.post(
                            Uri.parse("${apiUrl}users/redeemVoucher"),
                            headers: {
                              'Content-Type': 'application/json',
                              'authorization': 'Bearer ${AuthService.token}',
                              'x-api-key': dotenv.env['API_KEY']!,
                            },
                            body: jsonEncode({
                              'code': courtoCardController.text,
                              'user_id': AuthService.userData?["id"],
                            }),
                          );

                          Navigator.pop(ctx); // close loader

                          final data = jsonDecode(response.body);

                          if (data['success'] == true) {
                            courtoCardController.clear();
                            AuthService.userData?['wallet_balance'] =
                                data['wallet_balance'];

                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString(
                                'userData', jsonEncode(AuthService.userData));

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "تم شحن المحفظة بمبلغ ${data['voucher_value']} دينار. الرصيد الحالي: ${data['wallet_balance']} دينار.",
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            setState(() {});
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text(data['message'] ?? "حدث خطأ"),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        } catch (_) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("حدث خطأ أثناء الاتصال بالخادم."),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                    ),
                  ]
                : selectedMethod == "bank"
                    ? [
                        TextButton(
                          child: const Text("إلغاء"),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                        ElevatedButton(
                          child: const Text("الدفع"),
                          onPressed: () {
                            if (!_formKey.currentState!.validate()) return;

                            final amountLYD = int.parse(amountController.text);

                            Navigator.pop(ctx); // close dialog

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PaymentPage(amountLYD: amountLYD),
                              ),
                            );
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
