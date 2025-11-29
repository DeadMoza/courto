import 'package:courto/app_bar.dart';
import 'package:courto/pages/landing_page.dart';
import 'package:courto/pages/teams_page.dart';
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

  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _fields = [];
  List<Map<String, dynamic>> _discountedFields = [];
  bool _loadingFields = true;
  String? _fieldsErrorMessage;
  final apiUrl = dotenv.env['API_URL'];

  List<String> _carouselImages = [];
  String _carouselText1 = '';
  String _carouselText2 = '';


  List<Widget> _screens = [];
  Widget _buildPageTransition(int index) {
  final child = _screens[index];

  // Don't animate the map page (index 1)
  if (index == 2) return child;

  return AnimatedSwitcher(
    duration: const Duration(milliseconds: 200),
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    transitionBuilder: (Widget child, Animation<double> animation) {
      final offsetAnimation = Tween<Offset>(
        begin: const Offset(0.1, 0),
        end: Offset.zero,
      ).animate(animation);

      return FadeTransition(
        opacity: animation,
        child: SlideTransition(position: offsetAnimation, child: child),
      );
    },
    child: ValueKey(_selectedIndex) == ValueKey(index)
        ? child
        : const SizedBox.shrink(),
  );
}


  @override
  void initState() {
    super.initState();
    _fetchDiscountedFields();
    _detectCity();
    _fetchCarouselItems();
  }
  
  void _handleCityChanged(int newCityId) {
    if (_cityId != newCityId) {
      setState(() {
        _cityId = newCityId;
      });
      // Re-fetch fields for the newly selected city
      _fetchFields();
    }
  }

    Future<void> _fetchCities() async {
    try {
      final response = await http.get(Uri.parse('${apiUrl}users/getCities'),
      headers: {
        'x-api-key': '${dotenv.env['API_KEY']}'
      },);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _cities = data.map((city) => city as Map<String, dynamic>).toList();
        });
      } else {
        // Handle API error gracefully
      }
    } catch (e) {
      // Handle network or parsing error
    }
  }

Future<void> _fetchCarouselItems() async {
  try {
    final url = Uri.parse("${apiUrl}users/getCarouselItems");
    final res = await http.get(url, headers: {
      'x-api-key': '${dotenv.env['API_KEY']}'
    });

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data["images"] != null && data["images"] is List) {
        _carouselImages = List<String>.from(
          data["images"].map((img) => "${apiUrl}${img['carousel_image_url']}")
        );
      }

      if (data["text"] != null && data["text"] is List) {
        final texts = data["text"];
        _carouselText1 = texts.length > 0 ? texts[0]['carousel_text'] : '';
        _carouselText2 = texts.length > 1 ? texts[1]['carousel_text'] : '';
      }
    }
  } catch (e) {
    print("Error fetching carousel items: $e");
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
    await _fetchCities();
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

    Future<void> _fetchDiscountedFields() async {
    try {
      final url = Uri.parse("${apiUrl}users/getDiscountedFields");
      final res = await http.get(
        url,
        headers: {'x-api-key': '${dotenv.env['API_KEY']}'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["fields"] != null && data["fields"] is List) {
          _discountedFields = List<Map<String, dynamic>>.from(data["fields"]);
          
        } else {
          _discountedFields = [];
        }
      }
    } catch (e) {
      print("Error fetching discounted fields: $e");
      
    }
  }

    void goToFieldsPage() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  Future<void> _refreshApp() async {
  await _fetchCities();
  await _fetchFields();
  await _fetchDiscountedFields();
  await _fetchCarouselItems();
}

  

  void _initScreens() {
    _screens = [
      
      // HOME PAGE (with refresh)
      RefreshIndicator(
        onRefresh: _refreshApp,
        child: LandingPage(
          hasUpcomingBooking: false,
          discountedFields: _discountedFields,
          featuredText1: _carouselText1,
          featuredText2: _carouselText2,
          carouselImages: _carouselImages,
          onGoToFieldsPage: goToFieldsPage,
          matchesPlayedCount: 0,
        ),
      ),

      // FIELDS LIST PAGE (with refresh)
      RefreshIndicator(
        onRefresh: _refreshApp,
        child: FieldsListPage(
          key: ValueKey('FieldsListPage_$_cityId'),
          cityId: _cityId,
          fields: _fields,
          user_lat: _userLat,
          user_long: _userLng,
          loading: _loadingFields,
          errorMessage: _fieldsErrorMessage,
          onCityChanged: _handleCityChanged,
          cities: _cities,
        ),
      ),

      // MAP PAGE — NO REFRESH (keep it as is)
      FieldsMapPage(
        key: const PageStorageKey('FieldsMapPage'),
        initialLat: _userLat ?? 32.8872,
        initialLng: _userLng ?? 13.1913,
        cityLat: cityLatitude ?? 32.8872,
        cityLng: cityLongitude ?? 13.1913,
        fields: _fields,
        loading: _loadingFields,
      ),

      const TeamsPage(),
      const SettingsPage(key: PageStorageKey('SettingsPage')),
    ];

    setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    if (_loadingCity || _screens.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.redAccent),
        ),
      );
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.redAccent[100],
        appBar: buildHomeAppBar(context, isHome: true),

body: Stack(
  children: List.generate(_screens.length, (index) {
    final isActive = _selectedIndex == index;

    return AnimatedOpacity(
      key: ValueKey(index),
      duration: const Duration(milliseconds: 200),
      opacity: isActive ? 1 : 0,
      child: IgnorePointer(
        ignoring: !isActive,
        child: _buildPageTransition(index),
      ),
    );
  }),
),


        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.redAccent,
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
                icon: _buildIcon(Icons.home_rounded, 0),
                label: "الرئيسية",
              ),
              BottomNavigationBarItem(
                icon: _buildIcon(Icons.stadium, 1),
                label: "الملاعب",
              ),
              BottomNavigationBarItem(
                icon: _buildIconImage("assets/images/courto.png", 2),
                label: "الخريطة",
              ),
              BottomNavigationBarItem(
                icon: _buildIcon(Icons.people_alt_rounded, 3),
                label: "الفريق",
              ),
              BottomNavigationBarItem(
                icon: _buildIcon(Icons.menu, 4),
                label: "الإعدادات",
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white54,
            backgroundColor: Colors.redAccent,
            onTap: (i) {
              if (i == 3) return; // disable teams tab for now
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