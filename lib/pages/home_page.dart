import 'dart:convert';
import 'dart:ui' as ui;
import 'package:courto/app_bar.dart';
import 'package:courto/pages/landing_page.dart';
import 'package:courto/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../services/location_service.dart';
import 'fields_list_page.dart';
import 'fields_map_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final apiUrl = dotenv.env['API_URL'];

  int _selectedIndex = 0;
  int _cityId = 1;
  bool _loadingCity = true;

  double? _userLat;
  double? _userLng;
  double? cityLatitude;
  double? cityLongitude;

  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _fields = [];
  List<Map<String, dynamic>> _discountedFields = [];

  bool _loadingFields = true;
  String? _fieldsErrorMessage;

  List<String> _carouselImages = [];
  String _carouselText1 = '';
  String _carouselText2 = '';

  int _selectedTypeId = 1;
  int _matchesPlayedCount = 0;

  /// Cached tabs
  late List<Widget?> _screens;

  @override
  void initState() {
    super.initState();
    _screens = List.filled(4, null);
    _fetchDiscountedFields();
    _fetchCarouselItems();
    _detectCity();
  }

  /* ============================================================
     SCREEN FACTORY (LAZY LOAD + KEEP ALIVE)
  ============================================================ */

  void _buildScreenIfNeeded(int index) {
    if (_screens[index] != null) return;

    if (index == 0) {
      _screens[0] = RefreshIndicator(
        onRefresh: _refreshApp,
        child: LandingPage(
          hasUpcomingBooking: false,
          discountedFields: _discountedFields,
          featuredText1: _carouselText1,
          featuredText2: _carouselText2,
          carouselImages: _carouselImages,
          onGoToFieldsPage: goToFieldsPage,
          matchesPlayedCount: _matchesPlayedCount,
        ),
      );
    }

    if (index == 1) {
      _screens[1] = RefreshIndicator(
        onRefresh: _refreshApp,
        child: FieldsListPage(
          key: ValueKey('FieldsListPage_${_cityId}_$_selectedTypeId'),
          cityId: _cityId,
          fields: _fields,
          user_lat: _userLat,
          user_long: _userLng,
          loading: _loadingFields,
          errorMessage: _fieldsErrorMessage,
          onCityChanged: _handleCityChanged,
          cities: _cities,
          defaultSelectedTypeId: _selectedTypeId,
        ),
      );
    }

    if (index == 2) {
      _screens[2] = FieldsMapPage(
        initialLat: _userLat ?? 32.8872,
        initialLng: _userLng ?? 13.1913,
        cityLat: cityLatitude ?? 32.8872,
        cityLng: cityLongitude ?? 13.1913,
        fields: _fields,
        loading: _loadingFields,
      );
    }

    if (index == 3) {
      _screens[3] = SettingsPage(fields: _fields);
    }
  }

  /* ============================================================
     UI
  ============================================================ */

  @override
  Widget build(BuildContext context) {
    if (_loadingCity) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
      );
    }

    _buildScreenIfNeeded(_selectedIndex);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: buildHomeAppBar(context, isHome: true),

        body: Stack(
          children: List.generate(4, (i) {
            final screen = _screens[i];
            final active = _selectedIndex == i;
            if (screen == null) return const SizedBox();
            return Offstage(offstage: !active, child: screen);
          }),
        ),

        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).colorScheme.primary,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white54,
          showUnselectedLabels: true,
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "الرئيسية"),
            BottomNavigationBarItem(icon: Icon(Icons.stadium), label: "الملاعب"),
            BottomNavigationBarItem(icon: Icon(Icons.map), label: "الخريطة"),
            BottomNavigationBarItem(icon: Icon(Icons.menu), label: "الإعدادات"),
          ],
        ),
      ),
    );
  }

  /* ============================================================
     CITY + DATA
  ============================================================ */

  void _handleCityChanged(int newCityId) {
    if (_cityId == newCityId) return;
    _cityId = newCityId;
    _screens[1] = null;
    _screens[2] = null;
    _fetchFields();
    setState(() {});
  }

  void goToFieldsPage(int index) {
    _selectedIndex = 1;
    _selectedTypeId = index;
    _screens[1] = null;
    setState(() {});
  }

  Future<void> _refreshApp() async {
    await _fetchCities();
    await _fetchFields();
    await _fetchDiscountedFields();
    await _fetchCarouselItems();
    if (AuthService.isLoggedIn) await getMatchCount();
    _screens[0] = null;
    _screens[1] = null;
    setState(() {});
  }

  /* ============================================================
     API CALLS
  ============================================================ */

  Future<void> _fetchCities() async {
    try {
      final res = await http.get(Uri.parse('${apiUrl}users/getCities'),
          headers: {'x-api-key': '${dotenv.env['API_KEY']}'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _cities = List<Map<String, dynamic>>.from(data);
      }
    } catch (_) {}
  }

  Future<void> _fetchFields() async {
    _loadingFields = true;
    setState(() {});
    try {
      final res = await http.get(Uri.parse('${apiUrl}users/getFieldsByCity/$_cityId'),
          headers: {'x-api-key': '${dotenv.env['API_KEY']}'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _fields = List<Map<String, dynamic>>.from(data['fields'] ?? []);
        _fieldsErrorMessage = null;
      } else {
        _fieldsErrorMessage = "فشل تحميل الملاعب";
      }
    } catch (_) {
      _fieldsErrorMessage = "فشل الاتصال";
    }
    _loadingFields = false;
    setState(() {});
  }

  Future<void> _fetchDiscountedFields() async {
    try {
      final res = await http.get(Uri.parse('${apiUrl}users/getDiscountedFields'),
          headers: {'x-api-key': '${dotenv.env['API_KEY']}'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _discountedFields = List<Map<String, dynamic>>.from(data['fields'] ?? []);
        _refreshHomeTab();
      }
    } catch (_) {}
  }

  Future<void> _fetchCarouselItems() async {
    try {
      final res = await http.get(Uri.parse('${apiUrl}users/getCarouselItems'),
          headers: {'x-api-key': '${dotenv.env['API_KEY']}'});
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _carouselImages = (data['images'] as List?)
                ?.map((e) => '${apiUrl}${e['carousel_image_url']}')
                .cast<String>()
                .toList() ??
            [];
        final texts = data['text'] as List? ?? [];
        _carouselText1 = texts.isNotEmpty ? texts[0]['carousel_text'] : '';
        _carouselText2 = texts.length > 1 ? texts[1]['carousel_text'] : '';
        _refreshHomeTab();
      }
    } catch (_) {}
  }

  void _refreshHomeTab() {
  _screens[0] = null;
  if (_selectedIndex == 0) {
    setState(() {});
  }
}


  Future<void> _detectCity() async {
    LocationService.getUserLocation().then((pos) async {
      if (pos == null) return;

      _userLat = pos.latitude;
      _userLng = pos.longitude;
      try {
        final res = await http.post(Uri.parse('${apiUrl}users/getUserCity'),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': '${dotenv.env['API_KEY']}'
            },
            body: jsonEncode({'latitude': pos.latitude, 'longitude': pos.longitude}));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          _cityId = data['city_id'] ?? 1;
          cityLatitude = data['city_latitude'];
          cityLongitude = data['city_longitude'];
          _screens[1] = null;
          _fetchFields();
          setState(() {});
        }
      } catch (_) {}
    });
    _loadingCity = false;
    setState(() {});   // show UI instantly

    _fetchCities();
    _fetchFields();
    _fetchDiscountedFields();
    _fetchCarouselItems();
    if (AuthService.isLoggedIn) getMatchCount();

  }

  Future<void> getMatchCount() async {
    try {
      final id = AuthService.userData!['id'];
      final res = await http.get(Uri.parse('${apiUrl}users/getMatchCount/$id'),
          headers: {
            'authorization': 'Bearer ${AuthService.token}',
            'x-api-key': '${dotenv.env['API_KEY']}'
          });
      if (res.statusCode == 200) {
        _matchesPlayedCount = int.tryParse(jsonDecode(res.body)['count'].toString()) ?? 0;
        _refreshHomeTab();
      }
    } catch (_) {}
  }
}
