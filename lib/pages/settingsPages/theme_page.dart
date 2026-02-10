import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:courto/l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';

class ThemePage extends StatelessWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.themeTitle,
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
              _themeTile(
                context,
                icon: Icons.light_mode_outlined,
                title: t.themeLight,
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
              ),
              const Divider(height: 1),
              _themeTile(
                context,
                icon: Icons.dark_mode_outlined,
                title: t.themeDark,
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
              ),
              const Divider(height: 1),
              _themeTile(
                context,
                icon: Icons.settings_suggest_outlined,
                title: t.themeSystem,
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _themeTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required ThemeMode value,
    required ThemeMode groupValue,
  }) {
    final themeProvider = context.read<ThemeProvider>();
    final isSelected = value == groupValue;

    return RadioListTile<ThemeMode>(
      value: value,
      groupValue: groupValue,
      onChanged: (v) => themeProvider.setTheme(v!),
      secondary: Icon(
        icon,
        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: "Changa",
          fontSize: 16,
        ),
      ),
      activeColor: Theme.of(context).colorScheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
