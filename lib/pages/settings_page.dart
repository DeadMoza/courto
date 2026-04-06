import 'package:courto/pages/login_page.dart';
import 'package:courto/pages/settingsPages/favorites_page.dart';
import 'package:courto/pages/settingsPages/language_page.dart';
import 'package:courto/pages/settingsPages/policy_page.dart';
import 'package:courto/pages/settingsPages/subscriptions_page.dart';
import 'package:courto/pages/settingsPages/support_page.dart';
import 'package:courto/pages/settingsPages/theme_page.dart';
import 'package:courto/pages/signup_page.dart';
import 'package:flutter/material.dart';
import 'package:courto/pages/settingsPages/about_page.dart';
import 'package:courto/l10n/app_localizations.dart';
import '../charge_wallet_dialog.dart';
import '../services/auth_service.dart';
import 'settingsPages/booking_history_page.dart';

class SettingsPage extends StatelessWidget {
  final List<Map<String, dynamic>> fields;

  const SettingsPage({
    super.key,
    required this.fields,
  });

  void _logout(BuildContext context) async {
    await AuthService.clearSession();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _showLogoutConfirmation(BuildContext parentContext) {
    final t = AppLocalizations.of(parentContext)!;

    showDialog(
      context: parentContext,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t.logoutConfirmTitle),
          actions: <Widget>[
            TextButton(
              child: Text(t.no),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text(
                t.yes,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _logout(parentContext);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserHeader(BuildContext context, String userName, bool isLoggedIn) {
    final t = AppLocalizations.of(context)!;
    final userPhoneNumber = AuthService.userData?["phone_number"] ?? t.phoneNotAvailable;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      color: Theme.of(context).scaffoldBackgroundColor,
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Changa",
                ),
              ),
              if (isLoggedIn)
                Text(
                  userPhoneNumber,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontFamily: "Changa",
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    final isLoggedIn = AuthService.isLoggedIn;
    final String userName = isLoggedIn ? AuthService.fullName : t.pleaseLogin;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onPrimary,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUserHeader(context, userName, isLoggedIn),

            if (isLoggedIn) ...[
              const Divider(height: 1),
              SettingsTile(
                icon: Icons.history,
                title: t.bookingHistory,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BookingsHistoryPage()),
                  );
                },
              ),
              const Divider(height: 1),

              SettingsTile(
                icon: Icons.favorite,
                title: t.favoriteFields,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FavoritesPage(fields: fields)),
                  );
                },
              ),
              
              const Divider(height: 1),

              SettingsTile(
                icon: Icons.card_membership,
                title: t.subscriptionsPage,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SubscriptionsPage()),
                  );
                },
              ),
              const Divider(height: 1),

              SettingsTile(
                icon: Icons.support_agent,
                title: t.supportHelp,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SupportPage()),
                  );
                },
              ),
              const Divider(height: 1),

              SettingsTile(
                icon: Icons.account_balance_wallet,
                title: t.chargeWallet,
                onTap: () {
                  showChargeWalletDialog(context);
                },
              ),
              const Divider(height: 1),
            ],

            SettingsTile(
              icon: Icons.policy,
              title: t.termsTitle, // closest available key for "Terms/Policy" title
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PolicyPage()),
                );
              },
            ),
            const Divider(height: 1),

            SettingsTile(
              icon: Icons.info,
              title: t.aboutApp,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutAppPage()),
                );
              },
            ),
            const Divider(height: 1),

            SettingsTile(
              icon: Icons.language,
              title: t.appLanguage,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LanguagePage()),
                );
              },
            ),
            const Divider(height: 1),

            SettingsTile(
              icon: Icons.visibility,
              title: t.visibilityMode,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ThemePage()),
                );
              },
            ),
            const Divider(height: 1),

            if (isLoggedIn)
              SettingsTile(
                icon: Icons.logout,
                title: t.logout,
                iconColor: Theme.of(context).colorScheme.primary,
                onTap: () => _showLogoutConfirmation(context),
              )
            else
              SettingsTile(
                icon: Icons.login,
                title: t.login,
                iconColor: Theme.of(context).colorScheme.primary,
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
    this.iconColor,
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
          fontFamily: "Changa",
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
