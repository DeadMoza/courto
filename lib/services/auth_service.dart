import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static bool isLoggedIn = false;
  static Map<String, dynamic>? userData;
  static String? token;

  // Save token and user data persistently
  static Future<void> saveSession(Map<String, dynamic> user, String jwtToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sessionToken', jwtToken);
    await prefs.setString('userData', jsonEncode(user));
    userData = user;
    token = jwtToken;
    isLoggedIn = true;
  }

  // Load token and user data on app start
  static Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('sessionToken');
    final userString = prefs.getString('userData');

    if (token != null && userString != null) {
      userData = jsonDecode(userString) as Map<String, dynamic>;
      isLoggedIn = true;
    } else {
      isLoggedIn = false;
    }
  }

  // Clear session
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sessionToken');
    await prefs.remove('userData');
    token = null;
    userData = null;
    isLoggedIn = false;
  }
}
