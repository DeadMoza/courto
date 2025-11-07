import 'package:courto/pages/login_page.dart';
import 'package:courto/pages/settingsPages/policy_page.dart';
import 'package:courto/pages/signup_page.dart';
import 'package:flutter/material.dart';
import 'package:courto/pages/settingsPages/about_page.dart';
import '../charge_wallet_dialog.dart';
import '../services/auth_service.dart';
import 'settingsPages/booking_history_page.dart';

// Note: Assuming a separate page for Policy exists or will be created
// import 'settingsPages/policy_page.dart'; 


class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("تسجيل الخروج؟"),
          actions: <Widget>[
            TextButton(
              child: const Text('لا'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              // Highlight the affirmative action
              child: const Text('نعم', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog first
                _logout(context);
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
            backgroundColor: Colors.redAccent.withOpacity(0.2),
            child: Icon(
              isLoggedIn ? Icons.person : Icons.person_off, 
              color: Colors.redAccent, 
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
                icon: Icons.account_balance_wallet,
                title: "شحن المحفظة",
                onTap: () {
                  showChargeWalletDialog(context);
                },
              ),
            ],
            
        
            const Divider(height: 1),

            SettingsTile(
              icon: Icons.support_agent,
              title: "الدعم",
              onTap: () {
                // TODO: navigate to support page
              },
            ),
            const Divider(height: 1),

            SettingsTile(
              icon: Icons.policy,
              title: "سياسة الخصوصية",
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
                iconColor: Colors.red,
                onTap: () => _showLogoutConfirmation(context),
              )
            else
              SettingsTile(
                icon: Icons.login,
                title: "تسجيل الدخول",
                iconColor: Colors.red,
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
    this.iconColor = Colors.red,
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