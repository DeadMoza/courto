import 'package:courto/app_bar.dart';
import 'package:courto/pages/store_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/location_service.dart';
import 'fields_list_page.dart';
import 'fields_map_page.dart';
import 'settings_page.dart';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int _cityId = 1; // default Tripoli
  bool _loadingCity = true;

  double? _userLat;
  double? _userLng;
  double? cityLatitude;
  double? cityLongitude;

  List<Map<String, dynamic>> _fields = [];
  bool _loadingFields = true;
  String? _fieldsErrorMessage;
  final apiUrl = dotenv.env['API_URL'];

  List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _detectCity();
  }
  
  // 🆕 Function to handle city changes from FieldsListPage
  void _handleCityChanged(int newCityId) {
    if (_cityId != newCityId) {
      setState(() {
        _cityId = newCityId;
      });
      // Re-fetch fields for the newly selected city
      _fetchFields();
    }
  }

  Future<void> _detectCity() async {
    final position = await LocationService.getUserLocation();

    if (position != null) {
      _userLat = position.latitude;
      _userLng = position.longitude;

      try {
        final url = Uri.parse("${apiUrl}users/getUserCity");
        final res = await http.post(
          url,
          headers: {
            "Content-Type": "application/json",
            'x-api-key': '${dotenv.env['API_KEY']}'
          },
          body: jsonEncode({
            "latitude": position.latitude,
            "longitude": position.longitude,
          }),
        );

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          _cityId = data["city_id"] ?? 1;
          cityLatitude = data["city_latitude"];
          cityLongitude = data["city_longitude"];
        }
      } catch (_) {
        _cityId = 1;
      }
    }

    setState(() {
      _loadingCity = false;
    });

    // Fetch fields after detecting the city
    await _fetchFields();
  }

  Future<void> _fetchFields() async {
    setState(() {
      _loadingFields = true;
      _fieldsErrorMessage = null;
      // Re-initialize screens to show loading state immediately
      _initScreens(); 
    });

    try {
      final url = Uri.parse("${apiUrl}users/getFieldsByCity/$_cityId");
      final res = await http.get(
        url,
        headers: {'x-api-key': '${dotenv.env['API_KEY']}'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["fields"] != null && data["fields"] is List) {
          _fields = List<Map<String, dynamic>>.from(data["fields"]);
          _loadingFields = false;
          print(_fields);
          print("##################################################################");
        } else {
          _fields = [];
          _fieldsErrorMessage = "لا توجد ملاعب في هذه المدينة";
          _loadingFields = false;
        }
      } else {
        _fieldsErrorMessage = "فشل تحميل الملاعب";
        _loadingFields = false;
      }
    } catch (e) {
      print("Error fetching fields: $e");
      _fieldsErrorMessage = "فشل التحميل، تحقق من اتصالك بالإنترنت";
      _loadingFields = false;
    }

    // Must call _initScreens *again* to pass the final data and update the UI
    _initScreens();
  }

  void _initScreens() {
    _screens = [
      FieldsListPage(
        key: ValueKey('FieldsListPage_$_cityId'), // Key changed to use city ID for full widget rebuild on city change
        cityId: _cityId,
        fields: _fields,
        user_lat: _userLat,
        user_long: _userLng,
        loading: _loadingFields,
        errorMessage: _fieldsErrorMessage,
        onCityChanged: _handleCityChanged, // 🔑 The required argument is added here
      ),
      FieldsMapPage(
        key: const PageStorageKey('FieldsMapPage'),
        initialLat: _userLat ?? 32.8872,
        initialLng: _userLng ?? 13.1913,
        cityLat: cityLatitude ?? 32.8872,
        cityLng: cityLongitude ?? 13.1913,
        fields: _fields,
        loading: _loadingFields,
      ),
      const StorePage(),
      const SettingsPage(key: PageStorageKey('SettingsPage')),
    ];
    setState(() {}); // rebuild UI after initializing screens
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingCity || _screens.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.red),
        ),
      );
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.red[100],
        appBar: buildHomeAppBar(context, isHome: true),

        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),

        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.red,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
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
                icon: _buildIcon(Icons.storefront, 2),
                label: "المتجر",
              ),
              BottomNavigationBarItem(
                icon: _buildIcon(Icons.menu, 3),
                label: "الإعدادات",
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white54,
            backgroundColor: Colors.red,
            onTap: (i) {
              if (i == 2) return; // disable store tab for now
              setState(() => _selectedIndex = i);
            },
            showUnselectedLabels: true,
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;
    return AnimatedScale(
      scale: isSelected ? 1.3 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: Icon(
        icon,
        color: isSelected ? Colors.white : Colors.white54,
      ),
    );
  }

  Widget _buildIconImage(String assetPath, int index) {
    bool isSelected = _selectedIndex == index;
    return AnimatedScale(
      scale: isSelected ? 1.3 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: Image.asset(
        assetPath,
        color: isSelected ? Colors.white : Colors.white54,
        width: 28,
        height: 28,
      ),
    );
  }
}