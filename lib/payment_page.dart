import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:moamalat_payment/moamalat_payment.dart';
import 'services/auth_service.dart';

class PaymentPage extends StatelessWidget {
  final int amountLYD;

  const PaymentPage({super.key, required this.amountLYD});

  @override
  Widget build(BuildContext context) {
    final amountDirham = (amountLYD * 1000).toString();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        title: const Text("دفع المحفظة"),
        elevation: 0,
      ),
      backgroundColor: Colors.red[50], // Page background
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: MoamalatPaymentUnified(
            merchantId: dotenv.env['MOAMALAT_MERCHANT_ID']!,
            terminalId: dotenv.env['MOAMALAT_TERMINAL_ID']!,
            merchantSecretKey: dotenv.env['MOAMALAT_SECRET_KEY']!,
            merchantReference: "WALLET_${DateTime.now().millisecondsSinceEpoch}",
            amount: amountDirham,
            isTest: false,
            loadingMessage: "جاري تحويلك إلى بوابة الدفع...",
            onCompleteSucsses: (transaction) async {
              final apiUrl = dotenv.env['API_URL']; 

              try {
                final response = await http.post(
                  Uri.parse("${apiUrl}users/chargeWallet"),
                  headers: {
                    'Content-Type': 'application/json',
                    'authorization': 'Bearer ${AuthService.token}',
                    'x-api-key': dotenv.env['API_KEY']!,
                  },
                  body: jsonEncode({
                    'amount': amountLYD,
                    'user_id': AuthService.userData?["id"],
                    'transaction_reference': transaction.systemReference,
                  }),
                );

                if (response.statusCode == 200) {
                  final data = jsonDecode(response.body);

                  final walletBalance = data['wallet_balance'] ?? 0;

                  AuthService.userData?['wallet_balance'] = walletBalance;

                  Navigator.popUntil(context, ModalRoute.withName('/')); 

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "تم شحن المحفظة بمقدار $amountLYD الرصيد الجديد: $walletBalance دينار",
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                } else {
                  final data = jsonDecode(response.body);
                  print(data);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(data['message'] ?? "فشل تحديث المحفظة"),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              } catch (e) {
                print(e);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("حدث خطأ أثناء شحن المحفظة"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },

            onError: (error) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error.error ?? "حدث خطأ"),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
