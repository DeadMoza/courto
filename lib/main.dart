import 'dart:io';

import 'package:courto/pages/settingsPages/booking_history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/home_page.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ar', null);

  OneSignal.initialize("c897f37c-06d5-4d5e-b700-9c2bca2af312"); 
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

  // Ask for permission
  OneSignal.Notifications.requestPermission(true);

// get OneSignal player id
final id = await OneSignal.User.getOnesignalId();
if (id != null && id.isNotEmpty) {
  AuthService.playerId = id;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('playerId', id);
}

// Detect platform early
AuthService.platform = Platform.isAndroid
    ? 'android'
    : Platform.isIOS
        ? 'ios'
        : 'unknown';

final prefs = await SharedPreferences.getInstance();
await prefs.setString('platform', AuthService.platform!);

// Now load session
await AuthService.loadSession();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'courto',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Changa',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/bookingHistoryPage' : (context) => const BookingsHistoryPage()
      },
    );
  }
}
