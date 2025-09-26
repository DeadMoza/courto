import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import 'fields_list_page.dart';
import 'fields_map_page.dart';
import 'settings_page.dart';
import 'login_page.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int _cityId = 1; // default Tripoli
  bool _loadingCity = true;

  @override
  void initState() {
    super.initState();
    _detectCity();
  }

  Future<void> _detectCity() async {
    final position = await LocationService.getUserLocation();

    if (position != null) {
      try {
        final url = Uri.parse("${apiUrl}users/getUserCity");
        final res = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "latitude": position.latitude,
            "longitude": position.longitude, // fixed typo
          }),
        );

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          setState(() {
            _cityId = data["city_id"] ?? 1;
            _loadingCity = false;
          });
        } else {
          setState(() {
            _cityId = 1;
            _loadingCity = false;
          });
        }
      } catch (e) {
        setState(() {
          _cityId = 1;
          _loadingCity = false;
        });
      }
    } else {
      setState(() {
        _cityId = 1;
        _loadingCity = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingCity) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.red),
        ),
      );
    }

    final screens = [
      FieldsListPage(cityId: _cityId),
      const FieldsMapPage(),
      const SettingsPage(),
    ];

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.red,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              if (AuthService.isLoggedIn)
                Expanded(
                  child: Text(
                    AuthService.userData?['full_name'] ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                )
              else
                const Spacer(),
              _buildWallet(),
            ],
          ),
          leading: !AuthService.isLoggedIn
              ? IconButton(
                  icon: const Icon(Icons.login_rounded, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    ).then((_) {
                      setState(() {}); // refresh after login
                    });
                  },
                )
              : null,
        ),
        body: screens[_selectedIndex],
        bottomNavigationBar: Container(
          color: Colors.red,
          child: BottomNavigationBar(
            items: [
              BottomNavigationBarItem(
                icon: _buildIcon(Icons.stadium, 0),
                label: "الملاعب",
              ),
              BottomNavigationBarItem(
                icon: _buildIconImage("assets/images/courto.png", 1),
                label: "الخريطة",
              ),
              BottomNavigationBarItem(
                icon: _buildIcon(Icons.menu, 2),
                label: "الإعدادات",
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white54,
            backgroundColor: Colors.red,
            onTap: (i) => setState(() => _selectedIndex = i),
            showUnselectedLabels: true,
          ),
        ),
      ),
    );
  }

  Widget _buildWallet() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet,
              color: Colors.red, size: 22),
          const SizedBox(width: 4),
          Text(
            AuthService.userData?['wallet_balance']?.toString() ?? '0',
            style: const TextStyle(
                color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;
    return Transform.scale(
      scale: isSelected ? 1.2 : 1.0,
      child: Icon(icon, color: isSelected ? Colors.white : Colors.white54),
    );
  }

  Widget _buildIconImage(String assetPath, int index) {
    bool isSelected = _selectedIndex == index;
    return Transform.scale(
      scale: isSelected ? 1.2 : 1.0,
      child: Image.asset(
        assetPath,
        color: isSelected ? Colors.white : Colors.white54,
        width: 28,
        height: 28,
      ),
    );
  }
}
