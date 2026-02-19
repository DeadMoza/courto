import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:ui' as ui;
import 'dart:math' show cos, sqrt, asin;
import '../constants.dart';
import 'bookingsPages/field_details_page.dart';

class FieldsListPage extends StatefulWidget {
  final int cityId;
  final List<Map<String, dynamic>> fields;
  final double? user_lat;
  final double? user_long;
  final bool loading;
  final String? errorMessage;

  final Function(int newCityId) onCityChanged;
  final List<Map<String, dynamic>> cities;
  final int defaultSelectedTypeId;

  const FieldsListPage({
    super.key,
    required this.cityId,
    required this.fields,
    required this.user_lat,
    required this.user_long,
    required this.loading,
    this.errorMessage,
    required this.onCityChanged,
    required this.cities,
    required this.defaultSelectedTypeId,
  });

  @override
  State<FieldsListPage> createState() => _FieldsListPageState();
}

class _FieldsListPageState extends State<FieldsListPage> {
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _filteredFields = [];
  int _selectedSort = 1; // 1 = closest, 2 = cheapest

  late int _selectedTypeId;
  late int _selectedCityId;

  late double _userLat;
  late double _userLng;
  final apiUrl = dotenv.env['API_URL'];

  bool get _isEnglish => Localizations.localeOf(context).languageCode == "en";

  // City name mapping (API returns Arabic)
  static const Map<String, String> _cityNameEn = {
    "طرابلس": "Tripoli",
    "مصراتة": "Misrata",
    "بنغازي": "Benghazi",
    "الزاوية": "Zawiya",
    "الخمس":"Khoms",
    "سرت":"Surt",
    "درنة":"Derna",
    "طبرق":"Tobruk",
    "سبها":"Sabha",
    "صبراتة": "Subrata",
    "زوارة":"Zuwara"
  };

  @override
  void initState() {
    super.initState();
    _userLat = widget.user_lat ?? 0;
    _userLng = widget.user_long ?? 0;
    _selectedCityId = widget.cityId;
    _applyDefaultSelectionAndFilters();
  }

  @override
  void didUpdateWidget(covariant FieldsListPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.fields != widget.fields ||
        oldWidget.cityId != widget.cityId ||
        oldWidget.defaultSelectedTypeId != widget.defaultSelectedTypeId) {
      if (oldWidget.cityId != widget.cityId) {
        _selectedCityId = widget.cityId;
      }
      _applyDefaultSelectionAndFilters();
    }
  }

  void _applyDefaultSelectionAndFilters() {
    _selectedTypeId = widget.defaultSelectedTypeId;
    _applyFilters();
  }

  void _applyFilters() {
    if (widget.fields.isEmpty) {
      setState(() => _filteredFields = []);
      return;
    }

    List<Map<String, dynamic>> result = List.from(widget.fields);

    result = result.map((f) {
      double lat = double.tryParse(f["field_latitude"]?.toString() ?? "0") ?? 0;
      double lng = double.tryParse(f["field_longitude"]?.toString() ?? "0") ?? 0;
      double distance = _calculateDistance(_userLat, _userLng, lat, lng);

      return {
        ...f,
        'calculated_distance': distance,
        'calculated_total_price': double.tryParse(
              f["field_has_discount"] == true
                  ? (f["field_calculated_remaining_price_after_discount"] + f["field_calculated_booking_price"]).toString()
                  : (f["field_calculated_remaining_price"]+ f["field_calculated_booking_price"]).toString(),
            ) ??
            0,
        'original_total_price':
            double.tryParse(f["field_calculated_remaining_price"]?.toString() ?? "0") ?? 0,
        'discount_price':
            double.tryParse(f["field_calculated_remaining_price_after_discount"]?.toString() ?? "0") ?? 0,
        'has_discount': f["field_has_discount"] == true,
      };
    }).toList();

    String typeName = _getTypeName(_selectedTypeId);
    result = result.where((f) => f["field_type"]?.toString() == typeName).toList();
////////////////////////////////
    if (_selectedSort == 1) {
      result.sort((a, b) =>
          (a['calculated_distance'] as double).compareTo(b['calculated_distance'] as double));
    } else if (_selectedSort == 2) {
      result.sort((a, b) =>
          (a['calculated_total_price'] as double).compareTo(b['calculated_total_price'] as double));
    }
////////////////////////////////////////////////////////////////////////////////////////////////////////
    setState(() => _filteredFields = result);
  }

  String _getTypeName(int typeId) {
    switch (typeId) {
      case 1:
        return "football";
      case 2:
        return "basketball";
      case 3:
        return "tennis";
      case 4:
        return "padel";
      case 5:
        return "padbol";
      case 6:
        return "carting";
      case 7:
        return "paintball";
      case 8:
        return "golf";
      case 9:
        return "vollyball";
      default:
        return "";
    }
  }

  String _getTypeLabel(int typeId) {
    if (_isEnglish) {
      switch (typeId) {
        case 1:
          return "Football";
        case 2:
          return "Basketball";
        case 3:
          return "Tennis";
        case 4:
          return "Padel";
        case 5:
          return "Padbol";
        case 6:
          return "Karting";
        case 7:
          return "Paintball";
        case 8:
          return "Golf";
        case 9:
          return "Volleyball";
        default:
          return "All";
      }
    }

    switch (typeId) {
      case 1:
        return "كرة القدم";
      case 2:
        return "كرة السلة";
      case 3:
        return "تنس";
      case 4:
        return "بادل";
      case 5:
        return "بادبول";
      case 6:
        return "كارتينج";
      case 7:
        return "بينتبول";
      case 8:
        return "قولف";
      case 9:
        return "كرة الطائرة";
      default:
        return "الكل";
    }
  }

  String _getCityName(int cityId) {
    final String arabicName = widget.cities.firstWhere(
      (city) => city['city_id'] == cityId,
      orElse: () => {'city_name': 'المدينة غير معروفة'},
    )['city_name'] as String;

    if (_isEnglish) {
      return _cityNameEn[arabicName] ?? arabicName; // fallback if not mapped
    }
    return arabicName;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    if (lat1 == 0 || lon1 == 0 || lat2 == 0 || lon2 == 0) return double.infinity;
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        int tempSelectedTypeId = _selectedTypeId;
        int tempSelectedSort = _selectedSort;
        int tempSelectedCityId = _selectedCityId;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final List<Map<String, dynamic>> reorderedCities = [
              ...widget.cities.where((c) => c['city_id'] == tempSelectedCityId),
              ...widget.cities.where((c) => c['city_id'] != tempSelectedCityId),
            ];

            return Directionality(
              textDirection: _isEnglish ? ui.TextDirection.ltr : ui.TextDirection.rtl,
              child: AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                content: SingleChildScrollView(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _isEnglish ? "City" : "المدينة",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 6),

                        if (widget.cities.isEmpty)
                          Center(
                            child: Text(
                              _isEnglish ? "Loading cities..." : "جاري تحميل المدن...",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        else
                          SizedBox(
                            height: 48,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: reorderedCities.map((city) {
                                  final cityId = city['city_id'] as int;
                                  final cityNameAr = (city['city_name'] ?? '') as String;
                                  final cityLabel = _isEnglish
                                      ? (_cityNameEn[cityNameAr] ?? cityNameAr)
                                      : cityNameAr;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: _buildCityChip(
                                      label: cityLabel,
                                      cityId: cityId,
                                      selected: tempSelectedCityId == cityId,
                                      onTap: () {
                                        setDialogState(() => tempSelectedCityId = cityId);

                                        setState(() => _selectedCityId = cityId);
                                        Navigator.pop(context);
                                        widget.onCityChanged(cityId);
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),

                        const SizedBox(height: 5),
                        const Divider(),

                        Text(
                          _isEnglish ? "Field type" : "نوع الملعب",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 12),

                        SizedBox(
                          height: 120,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                const SizedBox(width: 8),
                                _buildTypeBox(
                                  icon: Icons.sports_soccer,
                                  label: _isEnglish ? "Football" : "كرة القدم",
                                  typeId: 1,
                                  selected: tempSelectedTypeId == 1,
                                  onTap: () {
                                    setDialogState(() => tempSelectedTypeId = 1);
                                    setState(() => _selectedTypeId = 1);
                                    Navigator.pop(context);
                                    _applyFilters();
                                  },
                                ),
                                const SizedBox(width: 12),
                                _buildTypeBox(
                                  icon: Icons.sports_basketball,
                                  label: _isEnglish ? "Basketball" : "كرة السلة",
                                  typeId: 2,
                                  selected: tempSelectedTypeId == 2,
                                  onTap: () {
                                    setDialogState(() => tempSelectedTypeId = 2);
                                    setState(() => _selectedTypeId = 2);
                                    Navigator.pop(context);
                                    _applyFilters();
                                  },
                                ),
                                const SizedBox(width: 12),
                                _buildTypeBox(
                                  icon: Icons.sports_baseball,
                                  label: _isEnglish ? "Tennis" : "تنس",
                                  typeId: 3,
                                  selected: tempSelectedTypeId == 3,
                                  onTap: () {
                                    setDialogState(() => tempSelectedTypeId = 3);
                                    setState(() => _selectedTypeId = 3);
                                    Navigator.pop(context);
                                    _applyFilters();
                                  },
                                ),
                                const SizedBox(width: 12),
                                _buildTypeBox(
                                  icon: Icons.sports_tennis,
                                  label: _isEnglish ? "Padel" : "بادل",
                                  typeId: 4,
                                  selected: tempSelectedTypeId == 4,
                                  onTap: () {
                                    setDialogState(() => tempSelectedTypeId = 4);
                                    setState(() => _selectedTypeId = 4);
                                    Navigator.pop(context);
                                    _applyFilters();
                                  },
                                ),
                                const SizedBox(width: 12),
                                _buildTypeBox(
                                  icon: Icons.sports_soccer,
                                  label: _isEnglish ? "Padbol" : "بادبول",
                                  typeId: 5,
                                  selected: tempSelectedTypeId == 5,
                                  onTap: () {
                                    setDialogState(() => tempSelectedTypeId = 5);
                                    setState(() => _selectedTypeId = 5);
                                    Navigator.pop(context);
                                    _applyFilters();
                                  },
                                ),
                                const SizedBox(width: 12),
                                _buildTypeBox(
                                  icon: Icons.airline_seat_recline_extra_rounded,
                                  label: _isEnglish ? "Karting" : "كارت",
                                  typeId: 6,
                                  selected: tempSelectedTypeId == 6,
                                  onTap: () {
                                    setDialogState(() => tempSelectedTypeId = 6);
                                    setState(() => _selectedTypeId = 6);
                                    Navigator.pop(context);
                                    _applyFilters();
                                  },
                                ),
                                const SizedBox(width: 12),
                                _buildTypeBox(
                                  icon: Icons.format_paint_rounded,
                                  label: _isEnglish ? "Paintball" : "بينت بول",
                                  typeId: 7,
                                  selected: tempSelectedTypeId == 7,
                                  onTap: () {
                                    setDialogState(() => tempSelectedTypeId = 7);
                                    setState(() => _selectedTypeId = 7);
                                    Navigator.pop(context);
                                    _applyFilters();
                                  },
                                ),
                                const SizedBox(width: 12),
                                _buildTypeBox(
                                  icon: Icons.golf_course,
                                  label: _isEnglish ? "Golf" : "قولف",
                                  typeId: 8,
                                  selected: tempSelectedTypeId == 8,
                                  onTap: () {
                                    setDialogState(() => tempSelectedTypeId = 8);
                                    setState(() => _selectedTypeId = 8);
                                    Navigator.pop(context);
                                    _applyFilters();
                                  },
                                ),
                                const SizedBox(width: 12),
                                _buildTypeBox(
                                  icon: Icons.sports_volleyball,
                                  label: _isEnglish ? "Volleyball" : "كرة الطائرة",
                                  typeId: 9,
                                  selected: tempSelectedTypeId == 9,
                                  onTap: () {
                                    setDialogState(() => tempSelectedTypeId = 9);
                                    setState(() => _selectedTypeId = 9);
                                    Navigator.pop(context);
                                    _applyFilters();
                                  },
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        const Divider(),

                        Text(
                          _isEnglish ? "Sort by" : "ترتيب حسب",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildSortBox(
                              label: _isEnglish ? "Distance" : "البعد",
                              selected: tempSelectedSort == 1,
                              onTap: () {
                                setDialogState(() => tempSelectedSort = 1);
                                setState(() => _selectedSort = tempSelectedSort);
                                Navigator.pop(context);
                                _applyFilters();
                              },
                            ),
                            _buildSortBox(
                              label: _isEnglish ? "Price" : "السعر",
                              selected: tempSelectedSort == 2,
                              onTap: () {
                                setDialogState(() => tempSelectedSort = 2);
                                setState(() => _selectedSort = tempSelectedSort);
                                Navigator.pop(context);
                                _applyFilters();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String getFirstImageUrl(List<dynamic> images) {
    if (images.isEmpty) return "";
    final url = images[0]?.toString() ?? "";
    if (url.isEmpty || url.startsWith("http")) return url;

    final baseUrl = apiUrl;
    try {
      return Uri.parse(baseUrl!).resolve(url).toString();
    } catch (e) {
      return baseUrl!.endsWith('/') ? '$baseUrl$url' : '$baseUrl/$url';
    }
  }
Widget _buildCityChip({
  required String label,
  required int cityId,
  required bool selected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap, // ✅ enable all cities
    child: Chip(
      label: Text(
        label,
        style: TextStyle(
          color: selected
              ? Theme.of(context).colorScheme.onPrimary
              : const Color(0xFF1E1E1E),
        ),
      ),
      backgroundColor:
          selected ? Theme.of(context).colorScheme.primary : Colors.grey[200],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
        side: BorderSide(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[300]!,
          width: selected ? 1.5 : 1,
        ),
      ),
    ),
  );
}


  Widget _buildTypeBox({
    required IconData icon,
    required String label,
    required int typeId,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 90,
        height: 100,
        decoration: BoxDecoration(
          color: selected ? Colors.red[100] : Theme.of(context).colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.primary : Colors.black,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 40),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortBox({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        height: 60,
        decoration: BoxDecoration(
          color: selected ? Colors.red[100] : Colors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: selected ? Theme.of(context).colorScheme.primary : Colors.black,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: selected ? Theme.of(context).colorScheme.primary : Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldCard(Map<String, dynamic> field) {
    final imageUrl = getFirstImageUrl(field["field_images"] ?? []);

    final fieldName = _isEnglish
        ? (field["field_english_name"] ?? field["field_name"] ?? "Field")
        : (field["field_name"] ?? 'ملعب غير مسمى');

    final hasDiscount = field['has_discount'] == true;
    final originalPrice = field['original_total_price'] as double;
    final discountPrice = field['discount_price'] as double;
    final discountPercent = hasDiscount
        ? (((originalPrice - discountPrice) / originalPrice) * 100).round()
        : 0;

    final bookingPrice = field["field_calculated_booking_price"];

    final openTime = field["field_open_time"] ?? '';
    final closeTime = field["field_close_time"] ?? '';
    final capacity = field["field_capacity"] ?? 0;
    final location = field["field_location"] ?? '';
    final distance = field['calculated_distance'] as double;

    final distanceText = distance.isFinite
        ? (_isEnglish
            ? "${distance.toStringAsFixed(1)} km"
            : "${distance.toStringAsFixed(1)} كم")
        : location;

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => FieldDetailsPage(field: field)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: Theme.of(context).cardTheme.color,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: Center(
                        child: Icon(Icons.sports_soccer, size: 40, color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ),
                ),
                if (hasDiscount)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        "-$discountPercent%",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fieldName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary, size: 16),
                          const SizedBox(width: 4),
                          Text(distanceText, style: TextStyle(color: Theme.of(context).colorScheme.onSecondary)),
                        ],
                      ),
                      hasDiscount
                          ? Row(
                              children: [
                                Text(
                                  _isEnglish
                                      ? "Booking: $bookingPrice | ${discountPrice.toStringAsFixed(2)}"
                                      : "الحجز: $bookingPrice | ${discountPrice.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  originalPrice.toStringAsFixed(2),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              _isEnglish
                                  ? "Booking: $bookingPrice | ${originalPrice.toStringAsFixed(2)}/hour"
                                  : "الحجز: $bookingPrice | ${originalPrice.toStringAsFixed(2)}/الساعة",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${AppFormat.formatArabicTime(openTime)} - ${AppFormat.formatArabicTime(closeTime)}",
                        style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary),
                      ),
                      Row(
                        children: [
                          Icon(Icons.people, color: Theme.of(context).colorScheme.primary, size: 16),
                          Text(" $capacity", style: TextStyle(color: Theme.of(context).colorScheme.onSecondary)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFiltersHeader() {
    String typeLabel = _getTypeLabel(_selectedTypeId);
    String sortLabel = _selectedSort == 1 ? (_isEnglish ? "Distance" : "البعد") : (_isEnglish ? "Price" : "السعر");
    String cityName = _getCityName(_selectedCityId);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _showFilterDialog,
                    child: Chip(
                      label: Text(
                        _isEnglish ? "City: $cityName" : "المدينة: $cityName",
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                        side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _showFilterDialog,
                    child: Chip(
                      label: Text(
                        _isEnglish ? "Type: $typeLabel" : "النوع: $typeLabel",
                        style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                        side: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _showFilterDialog,
                    child: Chip(
                      label: Text(
                        _isEnglish ? "Sort: $sortLabel" : "ترتيب: $sortLabel",
                        style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                        side: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.filter_list, color: Theme.of(context).colorScheme.primary),
            onPressed: _showFilterDialog,
            tooltip: _isEnglish ? "Filters" : "فلترة",
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildActiveFiltersHeader(),
        Expanded(
          child: Builder(
            builder: (context) {
              if (widget.loading) {
                return Center(
                  child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                );
              }

              if (widget.errorMessage != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      _isEnglish ? 'Error: ${widget.errorMessage}' : 'حدث خطأ: ${widget.errorMessage}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                );
              }

              if (_filteredFields.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      _isEnglish
                          ? "No ${_getTypeLabel(_selectedTypeId)} fields available right now in ${_getCityName(_selectedCityId)}."
                          : "لا توجد ملاعب ${_getTypeLabel(_selectedTypeId)} متاحة حالياً في مدينة ${_getCityName(_selectedCityId)}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemCount: _filteredFields.length,
                itemBuilder: (context, index) => _buildFieldCard(_filteredFields[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isEnglish ? ui.TextDirection.ltr : ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(child: _buildContent()),
      ),
    );
  }
}
