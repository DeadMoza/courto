import 'package:flutter/material.dart';

class AppTheme {
  // ----------------------------
  // LIGHT THEME
  // ----------------------------
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    fontFamily: 'Changa',

    scaffoldBackgroundColor: Colors.red[50],

    colorScheme: const ColorScheme.light(
      primary: Color(0xFFFF5252),
      onPrimary: Colors.white,
      onSecondary: Color(0xFF1E1E1E),

    ),

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.redAccent,
      foregroundColor: Colors.white,
      shadowColor: Colors.redAccent
    ),

    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    dividerTheme: DividerThemeData(
      color: Colors.grey.shade300,
      thickness: 1,
    ),

    listTileTheme: const ListTileThemeData(
      iconColor: Colors.redAccent,
      textColor: Colors.black,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: Colors.red[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.red[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );







  // ----------------------------
  // DARK THEME
  // ----------------------------
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    fontFamily: 'Changa',

    scaffoldBackgroundColor: const Color(0xFF2E2E2E),

    colorScheme: const ColorScheme.dark(
      primary: Color.fromRGBO(255, 91, 91, 1),
      onPrimary: Color(0xFF1E1E1E),
      onSecondary: Colors.white,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Color.fromRGBO(255, 91, 91, 1),
      shadowColor: Colors.white
    ),

    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    dividerTheme: DividerThemeData(
      color: Colors.grey.shade700,
      thickness: 1,
    ),

    listTileTheme: const ListTileThemeData(
      iconColor: Colors.redAccent,
      textColor: Colors.white,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF2E2E2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}
