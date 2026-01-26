import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        title: const Text("لغة التطبيق", style: TextStyle(fontFamily: "Changa")),
      ),
      body: Column(
        children: [
          RadioListTile<Locale>(
            value: const Locale('ar'),
            groupValue: languageProvider.locale,
            title: const Text("العربية", style: TextStyle(fontFamily: "Changa")),
            onChanged: (value) => languageProvider.setLocale(value!),
          ),
          // RadioListTile<Locale>(
          //   value: const Locale('en'),
          //   groupValue: languageProvider.locale,
          //   title: const Text("English"),
          //   onChanged: (value) => languageProvider.setLocale(value!),
          // ),
        ],
      ),
    );
  }
}
