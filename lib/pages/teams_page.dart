import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:courto/l10n/app_localizations.dart';

class TeamsPage extends StatelessWidget {
  const TeamsPage({super.key});
  
  @override
  Widget build(BuildContext context) {

    final t = AppLocalizations.of(context)!;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.groups, size: 80, color: Theme.of(context).colorScheme.onSecondary),
              const SizedBox(height: 16),
              Text(
                t.teamsComingSoon,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
