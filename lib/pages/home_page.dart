import 'package:courto/app_bar.dart';
import 'package:flutter/material.dart';
import '../services/location_service.dart';
import 'fields_list_page.dart';
import 'fields_map_page.dart';
import 'settings_page.dart';
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

  double? _userLat;
  double? _userLng;
  double? cityLatitude;
  double? cityLongitude;

  // New state for fields data
  List<Map<String, dynamic>> _fields = [];
  bool _loadingFields = true;
  String? _fieldsErrorMessage;

  @override
  void initState() {
    super.initState();
    _detectCity();
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
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "latitude": position.latitude,
            "longitude": position.longitude,
          }),
        );

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          setState(() {
            _cityId = data["city_id"] ?? 1;
            cityLatitude = data["city_latitude"];
            cityLongitude = data["city_longitude"];
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

    // After city detection is complete (whether successful or fallback)
    await _fetchFields();
  }

  // Moved API call from FieldsListPage
  Future<void> _fetchFields() async {
    setState(() {
      _loadingFields = true;
      _fieldsErrorMessage = null;
    });

    try {
      // Use the detected/default cityId
      final url = Uri.parse("${apiUrl}users/getFieldsByCity/$_cityId");
      final res = await http.get(url);

      print("getFieldByCity response: ${res.body}");

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data["fields"] != null && data["fields"] is List) {
          setState(() {
            _fields = List<Map<String, dynamic>>.from(data["fields"]);
            _loadingFields = false;
          });
        } else {
          setState(() {
            _fields = [];
            _fieldsErrorMessage = "لا توجد ملاعب في هذه المدينة";
            _loadingFields = false;
          });
        }
      } else {
        setState(() {
          _fieldsErrorMessage = "فشل تحميل الملاعب";
          _loadingFields = false;
        });
      }
    } catch (e) {
      print("Error fetching fields: $e");
      setState(() {
        _fieldsErrorMessage = "فشل التحميل، تحقق من اتصالك بالإنترنت";
        _loadingFields = false;
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
      // Pass data and state to FieldsListPage
      FieldsListPage(
        key: const PageStorageKey('FieldsListPage'), // Optional: helps preserve scroll position
        cityId: _cityId,
        fields: _fields,
        loading: _loadingFields,
        errorMessage: _fieldsErrorMessage,
      ),
      // Pass data and state to FieldsMapPage (Index 1)
      FieldsMapPage(
        key: const PageStorageKey('FieldsMapPage'), // Recommended for IndexedStack
        initialLat: _userLat ?? 32.8872, // Tripoli fallback
        initialLng: _userLng ?? 13.1913,
        cityLat: cityLatitude ?? 32.8872,
        cityLng: cityLongitude ?? 13.1913,
        fields: _fields, // Pass the fetched fields
        loading: _loadingFields,
      ),
      const SettingsPage(
        key: PageStorageKey('SettingsPage'),
      ),
    ];

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: buildHomeAppBar(context, isHome: true),
        body: IndexedStack(
          index: _selectedIndex,
          children: screens,
        ),
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