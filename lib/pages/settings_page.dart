import 'package:courto/pages/settingsPages/about_page.dart';
import 'package:flutter/material.dart';
import '../charge_wallet_dialog.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'settingsPages/booking_history_page.dart';


class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _logout(BuildContext context) async {
    await AuthService.clearSession();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loggedInOptions = [
      {
        "icon": Icons.history,
        "title": "سجل الحجوزات",
        "onTap": () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BookingsHistoryPage()),
          );
        }
      },
      {
        "icon": Icons.account_balance_wallet,
        "title": "شحن المحفظة",
        "onTap": () {
          showChargeWalletDialog(context);
        }
      },
      {
        "icon": Icons.support_agent,
        "title": "الدعم",
        "onTap": () {
          // TODO: navigate to support page
        }
      },
      {
        "icon": Icons.info,
        "title": "حول التطبيق",
        "onTap": () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutAppPage()),
          );
        }
      },
      {
        "icon": Icons.logout,
        "title": "تسجيل الخروج",
        "onTap": () => showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("تسجيل الخروج؟"),
                  actions: <Widget>[
                    TextButton(
                      child: Text('نعم'),
                      onPressed: () {
                        _logout(context);
                      },
                    ),
                    TextButton(
                      child: Text('لا'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                );
              },
            )
      },
    ];

    final loggedOutOptions = [
      {
        "icon": Icons.info,
        "title": "حول التطبيق",
        "onTap": () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutAppPage()),
          );
        }
      },
      {
        "icon": Icons.login,
        "title": "تسجيل الدخول",
        "onTap": () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
      },
    ];

    // Pick the list depending on login state
    final options = AuthService.isLoggedIn ? loggedInOptions : loggedOutOptions;

    return Scaffold(
      backgroundColor: Colors.red[50],
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: options.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final option = options[index];
          return ListTile(
            leading: Icon(option["icon"] as IconData, color: Colors.red),
            title: Text(
              option["title"] as String,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: option["onTap"] as void Function(),
          );
        },
      ),
    );
  }
}
