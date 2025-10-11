import 'dart:convert';
import 'dart:io' show Platform; // For detecting platform
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../constants.dart';

class AuthService {
  static bool isLoggedIn = false;
  static Map<String, dynamic>? userData;
  static String? token;
  static String? playerId;
  static String? platform; 

  /// Save session after successful signup/login
static Future<void> saveSession(Map<String, dynamic> user, String jwtToken) async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setString('sessionToken', jwtToken);
  await prefs.setString('userData', jsonEncode(user));
  userData = user;
  token = jwtToken;
  isLoggedIn = true;

  if (user['user_id'] != null) {
    await OneSignal.login(user['id'].toString());

    // Try to get playerId from OneSignal, fallback to existing value
    final oneSignalId = await OneSignal.User.getOnesignalId();
    playerId = oneSignalId ?? playerId; // keep main.dart value if OneSignal returns null
    if (playerId != null) await prefs.setString('playerId', playerId!);

    // Detect platform (if not already set)
    platform ??= Platform.isAndroid
        ? 'android'
        : Platform.isIOS
            ? 'ios'
            : 'unknown';
    await prefs.setString('platform', platform!);
  }
}


  /// Load session from local storage
  static Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('sessionToken');
    final userString = prefs.getString('userData');
    playerId = prefs.getString('playerId');
    platform = prefs.getString('platform');

    if (token != null && userString != null) {
      userData = jsonDecode(userString) as Map<String, dynamic>;
      isLoggedIn = true;

      if (userData?['user_id'] != null) {
        await OneSignal.login(userData!['user_id'].toString());

        // refresh playerId if missing
        if (playerId == null) {
          final id = await OneSignal.User.getOnesignalId();
          if (id != null) {
            playerId = id;
            await prefs.setString('playerId', playerId!);

            platform = Platform.isAndroid
                ? 'android'
                : Platform.isIOS
                    ? 'ios'
                    : 'unknown';
            await prefs.setString('platform', platform!);
          }
        }
      }
    } else {
      await clearSession();
    }
  }

  /// Logout user and clear session
  static Future<void> clearSession() async {
    try {
      if (userData!['id'] != null) {
        final res = await http.delete(
          Uri.parse("${apiUrl}users/removeDevice"),
          headers: {"Content-Type": "application/json", "authorization": "Bearer $token"},
          body: jsonEncode({
            "user_id": userData!['id'],
            "device_id": playerId,
          }),
        ); print("#########################################"); print(res.body);
      }
    // ignore: empty_catches
    } catch (e) {
     
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sessionToken');
    await prefs.remove('userData');

    token = null;
    userData = null;
    isLoggedIn = false;

    await OneSignal.logout();
  }

  static double get walletBalance {
    return double.tryParse(userData!['wallet_balance']?.toString() ?? '0') ?? 0;
  }

  static String get fullName {
    return userData?['full_name']?.toString() ?? '';
  }
}
