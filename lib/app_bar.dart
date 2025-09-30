import 'package:flutter/material.dart';
import 'package:courto/pages/signup_page.dart';
import 'services/auth_service.dart';
import 'charge_wallet_dialog.dart';

PreferredSizeWidget buildHomeAppBar(BuildContext context, {String? title}) {
  return AppBar(
    elevation: 0,
    backgroundColor: Colors.red,
    automaticallyImplyLeading: false,
    title: Row(
      children: [
        if (AuthService.isLoggedIn)
          Expanded(
            child: Text(
              title ?? AuthService.userData?['full_name'] ?? '',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          )
        else
          const Spacer(),
        GestureDetector(
          onTap: () => showChargeWalletDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet,
                    color: Colors.red, size: 22),
                const SizedBox(width: 4),
                Text(
                  AuthService.userData?['wallet_balance']?.toString() ?? '0',
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
    leading: !AuthService.isLoggedIn
        ? IconButton(
            icon: const Icon(Icons.login_rounded, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignupPage()),
              ).then((_) {
                // refresh after login
              });
            },
          )
        : null,
  );
}
