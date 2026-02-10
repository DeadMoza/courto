import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:courto/l10n/app_localizations.dart';
import '../../providers/language_provider.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.appLanguage,
          style: const TextStyle(fontFamily: "Changa"),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _languageTile(
                context,
                icon: Icons.g_translate,
                title: t.arabic,
                value: const Locale('ar'),
                groupValue: languageProvider.locale,
              ),
              const Divider(height: 1),
              _languageTile(
                context,
                icon: Icons.font_download,
                title: t.english,
                value: const Locale('en'),
                groupValue: languageProvider.locale,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _languageTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Locale value,
    required Locale groupValue,
  }) {
    final languageProvider = context.read<LanguageProvider>();
    final isSelected = value.languageCode == groupValue.languageCode;

    return RadioListTile<Locale>(
      value: value,
      groupValue: groupValue,
      onChanged: (v) => languageProvider.setLocale(v!),
      secondary: Icon(
        icon,
        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
      ),
      title: Text(
        title,
        style: const TextStyle(fontFamily: "Changa", fontSize: 16),
      ),
      activeColor: Theme.of(context).colorScheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
