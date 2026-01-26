import 'package:flutter/material.dart';
import 'package:courto/pages/signup_page.dart';
import 'services/auth_service.dart';
import 'charge_wallet_dialog.dart';
PreferredSizeWidget buildHomeAppBar(BuildContext context, {String? title, bool isHome = false}) {
  return AppBar(
    elevation: 0,
    backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
    foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
    automaticallyImplyLeading: false,
    // FIX: Restructure the title Row to prevent overflow
    title: Row(
      // Ensure content is spaced out across the AppBar width
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [

        if (AuthService.isLoggedIn || title != null)
        GestureDetector(
          onTap: () => showChargeWalletDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).appBarTheme.foregroundColor,
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_balance_wallet,
                    color: Theme.of(context).appBarTheme.shadowColor, size: 22),
                const SizedBox(width: 4),
                Text(
                  AuthService.walletBalance.toStringAsFixed(2),
                  style: TextStyle(color: Theme.of(context).appBarTheme.shadowColor, fontWeight: FontWeight.bold),
                )
              ],
            ),
          ),
        ),
          const Spacer(),

          Text(
            title ?? "Courto",
            maxLines: 1, 
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 30,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
          )
      ],
    ),
    leading: isHome
        ? (!AuthService.isLoggedIn
            ? IconButton(
                icon: const Icon(Icons.login_rounded, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupPage()),
                  );
                },
              )
            : null)
        : IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
  );
}