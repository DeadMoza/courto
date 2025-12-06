import 'package:courto/pages/login_page.dart';
import 'package:courto/pages/settingsPages/favorites_page.dart';
import 'package:courto/pages/settingsPages/policy_page.dart';
import 'package:courto/pages/settingsPages/support_page.dart';
import 'package:courto/pages/signup_page.dart';
import 'package:flutter/material.dart';
import 'package:courto/pages/settingsPages/about_page.dart';
import '../charge_wallet_dialog.dart';
import '../services/auth_service.dart';
import 'settingsPages/booking_history_page.dart';


class SettingsPage extends StatelessWidget {
    final List<Map<String, dynamic>> fields;

  
  const SettingsPage(
    {
      super.key,
      required this.fields,
    }
  );

  void _logout(BuildContext context) async {
    // Perform session clear
    await AuthService.clearSession();

    // Navigate to Signup and remove all previous routes
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

void _showLogoutConfirmation(BuildContext parentContext) {
  showDialog(
    context: parentContext,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("تسجيل الخروج؟"),
        actions: <Widget>[
          TextButton(
            child: const Text('لا'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('نعم', style: TextStyle(color: Colors.redAccent)),
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              _logout(parentContext);      // USE PARENT CONTEXT
            },
          ),
        ],
      );
    },
  );
}


  Widget _buildUserHeader(BuildContext context, String userName, bool isLoggedIn) {
    final userPhoneNumber = AuthService.userData?["phone_number"] ?? "لا يتوفر رقم";

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      color: Colors.red[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.red.withOpacity(0.2),
            child: Icon(
              isLoggedIn ? Icons.person : Icons.person_off, 
              color: Colors.red, 
              size: 30,
            ),
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                userName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: "Changa"),
              ),
              if (isLoggedIn)
                Text(
                  userPhoneNumber,
                  style: const TextStyle(fontSize: 14, color: Colors.grey, fontFamily: "Changa"),
                ),
            ],
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    print(fields);
    final isLoggedIn = AuthService.isLoggedIn;
    final String userName = isLoggedIn ? AuthService.fullName : "يرجى تسجيل الدخول"; 

    return Scaffold(
      backgroundColor: Colors.white, 
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. User Header
            _buildUserHeader(context, userName, isLoggedIn),

            if (isLoggedIn) ...[
              const Divider(height: 1),
              
              SettingsTile(
                icon: Icons.history,
                title: "سجل الحجوزات",
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsHistoryPage()));
                },
              ),
              const Divider(height: 1),

              SettingsTile(
                icon: Icons.favorite,
                title: "الملاعب المفضلة",
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => FavoritesPage(fields: fields)));
                },
              ),

              const Divider(height: 1),

              SettingsTile(
                icon: Icons.support_agent,
                title: "الدعم و المساعدة",
                onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportPage()));
                },
              ),

              const Divider(height: 1),
              
              SettingsTile(
                icon: Icons.account_balance_wallet,
                title: "شحن المحفظة",
                onTap: () {
                  showChargeWalletDialog(context);
                },
              ),
              const Divider(height: 1),
            ],
            
        

            SettingsTile(
              icon: Icons.policy,
              title: "شروط الاستخدام",
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PolicyPage()));
              },
            ),
            const Divider(height: 1),
            
            SettingsTile( 
              icon: Icons.info,
              title: "حول التطبيق",
              onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutAppPage()));
              },
            ),

            const Divider(height: 1),
            
            if (isLoggedIn) 
              SettingsTile(
                icon: Icons.logout,
                title: "تسجيل الخروج",
                iconColor: Colors.redAccent,
                onTap: () => _showLogoutConfirmation(context),
              )
            else
              SettingsTile(
                icon: Icons.login,
                title: "تسجيل الدخول",
                iconColor: Colors.redAccent,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupPage()),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}


class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;

  const SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor = Colors.redAccent,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16, 
          fontWeight: FontWeight.w500,
          fontFamily: "Changa"
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}