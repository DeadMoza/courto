import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

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
    final options = [
      {
        "icon": Icons.history,
        "title": "سجل الحجوزات",
        "onTap": () {
          // TODO: navigate to booking history page
        }
      },
      {
        "icon": Icons.account_balance_wallet,
        "title": "شحن المحفظة",
        "onTap": () {
          // TODO: navigate to charge wallet page
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
          // TODO: navigate to about page
        }
      },
      {
        "icon": Icons.logout,
        "title": "تسجيل الخروج",
        "onTap": () => _logout(context),
      },
    ];

    return Scaffold(
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
