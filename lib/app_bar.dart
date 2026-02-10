import 'package:flutter/material.dart';
import 'package:courto/pages/signup_page.dart';
import 'services/auth_service.dart';
import 'charge_wallet_dialog.dart';

// ✅ Localization
import 'package:courto/l10n/app_localizations.dart';

PreferredSizeWidget buildHomeAppBar(
  BuildContext context, {
  String? title,
  bool isHome = false,
}) {
  final t = AppLocalizations.of(context)!;

  return AppBar(
    elevation: 0,
    backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
    foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
    automaticallyImplyLeading: false,

    title: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (AuthService.isLoggedIn || title != null)
                Text(
          title ?? t.appName, 
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 30,
            color: Theme.of(context).appBarTheme.foregroundColor,
            fontFamily: "Changa",
          ),
        ),
        const Spacer(),
          GestureDetector(
            onTap: () => showChargeWalletDialog(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).appBarTheme.foregroundColor,
                borderRadius: BorderRadius.circular(5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.redAccent,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: Theme.of(context).appBarTheme.shadowColor,
                    size: 22,
                  ),
                  const SizedBox(width: 4),

                  Text(
                    AuthService.walletBalance.toStringAsFixed(2),
                    style: TextStyle(
                      color: Theme.of(context).appBarTheme.shadowColor,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Changa",
                    ),
                  ),
                ],
              ),
            ),
          ),



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
