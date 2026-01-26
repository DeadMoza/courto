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
  
  // NOTE: This variable is initialized in _applyDefaultSelectionAndFilters
  late int _selectedTypeId; 

  late int _selectedCityId; // Holds the currently selected City ID

  late double _userLat;
  late double _userLng;
  final apiUrl = dotenv.env['API_URL']; 

  @override
  void initState() {
    super.initState();
    _userLat = widget.user_lat ?? 0;
    _userLng = widget.user_long ?? 0;
    _selectedCityId = widget.cityId; 

    // Use the combined method for initial setup
    _applyDefaultSelectionAndFilters();
  }

  @override
  void didUpdateWidget(covariant FieldsListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if the data, city, or the default selection type has changed
    if (oldWidget.fields != widget.fields || 
        oldWidget.cityId != widget.cityId || 
        oldWidget.defaultSelectedTypeId != widget.defaultSelectedTypeId) { // <-- Crucial check for navigation
      
      if (oldWidget.cityId != widget.cityId) {
        _selectedCityId = widget.cityId;
      }
      
      _applyDefaultSelectionAndFilters();
    }
  }
  
  // New method to apply the initial filter selected from the home screen
  void _applyDefaultSelectionAndFilters() {
    // 1. Set the correct category ID from the parent widget before filtering
    _selectedTypeId = widget.defaultSelectedTypeId; 

    // 2. Now apply the filters
    _applyFilters();
  }

  void _applyFilters() {
    // Check if the widget fields list is null or empty before proceeding
    if (widget.fields.isEmpty) {
      setState(() => _filteredFields = []);
      return;
    }
    
    List<Map<String, dynamic>> result = List.from(widget.fields);

    // 1. Pre-calculate and store distance (Performance optimization)
    result = result.map((f) {
      double lat = double.tryParse(f["field_latitude"]?.toString() ?? "0") ?? 0;
      double lng = double.tryParse(f["field_longitude"]?.toString() ?? "0") ?? 0;
      double distance = _calculateDistance(_userLat, _userLng, lat, lng);

      return {
        ...f,
        'calculated_distance': distance,
        'calculated_total_price': double.tryParse(
                                    f["field_has_discount"] == true
                                        ? f["field_calculated_remaining_price_after_discount"]?.toString() ?? "0"
                                        : f["field_calculated_remaining_price"]?.toString() ?? "0"
                                  ) ?? 0,

        'original_total_price': double.tryParse(f["field_calculated_remaining_price"]?.toString() ?? "0") ?? 0,
        'discount_price': double.tryParse(f["field_calculated_remaining_price_after_discount"]?.toString() ?? "0") ?? 0,
        'has_discount': f["field_has_discount"] == true,

                              };

    }).toList();

    String typeName = _getTypeName(_selectedTypeId);
    result = result.where((f) {
      return f["field_type"]?.toString() == typeName;
    }).toList();

    // 3. Sort by selected mode
    if (_selectedSort == 1) {
      result.sort((a, b) {
        double distA = a['calculated_distance'] as double;
        double distB = b['calculated_distance'] as double;
        return distA.compareTo(distB);
      });
    } else if (_selectedSort == 2) {
      result.sort((a, b) {
        double priceA = a['calculated_total_price'] as double;
        double priceB = b['calculated_total_price'] as double;
        return priceA.compareTo(priceB);
      });
    }

    setState(() => _filteredFields = result);
  }

  String _getTypeName(int typeId) {
    switch (typeId) {
      case 1: return "football";
      case 2: return "basketball";
      case 3: return "tennis";
      case 4: return "padel";
      case 5: return "padbol";
      case 6: return "carting";
      case 7: return "paintball";
      case 8: return "golf";
      case 9: return "vollyball";
      default: return ""; // Should ideally not happen if typeId is controlled
    }
  }

  String _getTypeLabel(int typeId) {
    switch (typeId) {
      case 1: return "كرة القدم";
      case 2: return "كرة السلة";
      case 3: return "تنس";
      case 4: return "بادل";
      case 5: return "بادبول";
      case 6: return "كارتينج";
      case 7: return "بينتبول";
      case 8: return "قولف";
      case 9: return "كرة الطائرة";
      default: return "الكل";
    }
  }

  String _getCityName(int cityId) {
    return widget.cities.firstWhere(
      (city) => city['city_id'] == cityId,
      orElse: () => {'city_name': 'المدينة غير معروفة'},
    )['city_name'] as String;
  }

  // Haversine formula
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
      // Hold the current selections temporarily
      int tempSelectedTypeId = _selectedTypeId;
      int tempSelectedSort = _selectedSort;
      int tempSelectedCityId = _selectedCityId;

      return StatefulBuilder(
        builder: (context, setDialogState) {
          // ✅ Reorder cities: selected first
          final List<Map<String, dynamic>> reorderedCities = [
            ...widget.cities.where((c) => c['city_id'] == tempSelectedCityId),
            ...widget.cities.where((c) => c['city_id'] != tempSelectedCityId),
          ];

          return Directionality(
            textDirection: ui.TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              content: SingleChildScrollView(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // --- City Filter Section ---
                      const Text("المدينة",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),

                      if (widget.cities.isEmpty)
                        const Center(
                          child: Text("جاري تحميل المدن...",
                              style: TextStyle(color: Colors.grey)),
                        )
                      else
                        SizedBox(
                          height: 48,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: reorderedCities.map((city) {
                                final cityId = city['city_id'] as int;
                                final cityName = city['city_name'] as String;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: _buildCityChip(
                                    label: cityName,
                                    cityId: cityId,
                                    selected: tempSelectedCityId == cityId,
                                    onTap: () {
                                      // ✅ update temp selection so UI updates if you ever keep dialog open
                                      setDialogState(() => tempSelectedCityId = cityId);

                                      // your original logic: close dialog + fetch
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

                      // --- Field Type Filter Section ---
                      const Text("نوع الملعب",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                                label: "كرة القدم",
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
                                label: "كرة السلة",
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
                                label: "تنس",
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
                                label: "بادل",
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
                                label: "بادبول",
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
                                label: "كارت",
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
                                label: "بينت بول",
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
                                label: "قولف",
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
                                label: "كرة الطائرة",
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

                      // --- Sorting Section ---
                      const Text("ترتيب حسب",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSortBox(
                            label: "البعد",
                            selected: tempSelectedSort == 1,
                            onTap: () {
                              setDialogState(() => tempSelectedSort = 1);
                              setState(() => _selectedSort = tempSelectedSort);
                              Navigator.pop(context);
                              _applyFilters();
                            },
                          ),
                          _buildSortBox(
                            label: "السعر",
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

  // Improved URL helper
  String getFirstImageUrl(List<dynamic> images) {
    if (images.isEmpty) return "";
    final url = images[0]?.toString() ?? "";
    if (url.isEmpty || url.startsWith("http")) return url;

    final baseUrl = apiUrl;
    try {
      // Handles both absolute and relative path resolution
      return Uri.parse(baseUrl!).resolve(url).toString();
    } catch (e) {
      // Fallback for non-standard path
      return baseUrl!.endsWith('/') ? '$baseUrl$url' : '$baseUrl/$url';
    }
  }

  Widget _buildCityChip({
    required String label,
    required int cityId,
    required bool selected,
    required VoidCallback onTap,
  }) {
    // Disable non-Tripoli cities based on your business logic
    bool isTripoli = label == 'طرابلس' || label.toLowerCase() == 'tripoli';
    bool isDisabled = !isTripoli;

    return GestureDetector(
      onTap: isDisabled ? null : onTap, // disable tap if not Tripoli
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1.0, 
        child: Chip(
          label: Text(
            label,
            style: TextStyle(color: selected ? Theme.of(context).colorScheme.onPrimary : Color(0xFF1E1E1E)),
          ),
          backgroundColor:
              selected ? Theme.of(context).colorScheme.primary : Colors.grey[200],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            side: BorderSide(
              color: selected ? Theme.of(context).colorScheme.primary : Colors.grey[300]!,
              width: selected ? 1.5 : 1,
            ),
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
            Icon(icon, color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.primary, size: 40),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSecondary)),
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
          child: Text(label, style: TextStyle(color: selected ? Theme.of(context).colorScheme.primary : Colors.black)),
        ),
      ),
    );
  }

  Widget _buildFieldCard(Map<String, dynamic> field) {
    final imageUrl = getFirstImageUrl(field["field_images"] ?? []);
    final fieldName = field["field_name"] ?? 'ملعب غير مسمى';
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
        ? "${distance.toStringAsFixed(1)} كم"
        : location;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FieldDetailsPage(field: field)),
        );
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
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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
                          Text(distanceText, style:  TextStyle(color: Theme.of(context).colorScheme.onSecondary)),
                        ],
                      ),
                      hasDiscount
                      ? Row(
                          children: [
                            Text(
                              "الحجز: ${bookingPrice} | ${discountPrice.toStringAsFixed(2)}",
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
                          "الحجز: ${bookingPrice} | ${originalPrice.toStringAsFixed(2)}/الساعة",
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
                        // AppFormat is assumed to be available
                        "${AppFormat.formatArabicTime(openTime)} - ${AppFormat.formatArabicTime(closeTime)}",
                        style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.primary),
                      ),
                      Row(
                        children: [
                         Icon(Icons.people, color: Theme.of(context).colorScheme.primary, size: 16),
                          Text(" $capacity", style: TextStyle(color: Theme.of(context).colorScheme.onSecondary,)),
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

  // Updated Widget: Header showing active filters + City
  Widget _buildActiveFiltersHeader() {
    String typeLabel = _getTypeLabel(_selectedTypeId);
    String sortLabel = _selectedSort == 1 ? "البعد" : "السعر";
    String cityName = _getCityName(_selectedCityId);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // HORIZONTALLY SCROLLABLE FILTERS
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row( 
                children: [
                  GestureDetector(
                    onTap: _showFilterDialog,
                    child: Chip(
                      label: Text("المدينة: $cityName", style: const TextStyle(color: Colors.white)),
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
                      label: Text("النوع: ${typeLabel}", style: TextStyle(color: Theme.of(context).colorScheme.onSecondary)),
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
                      label: Text("ترتيب: $sortLabel", style: TextStyle(color: Theme.of(context).colorScheme.onSecondary)),
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

          // Filter Button (already opens dialog)
          IconButton(
            icon: Icon(Icons.filter_list, color: Theme.of(context).colorScheme.primary),
            onPressed: _showFilterDialog,
            tooltip: "فلترة",
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // The filters header is built regardless of the loading/error/empty state
    return Column(
      children: [
        _buildActiveFiltersHeader(), // Filters Header is always visible

        Expanded(
          child: Builder(
            builder: (context) {
              if (widget.loading) {
                return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
              }

              if (widget.errorMessage != null) {
                return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text('حدث خطأ: ${widget.errorMessage}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                    ));
              }

              if (_filteredFields.isEmpty) {
                return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                          "لا توجد ملاعب ${_getTypeLabel(_selectedTypeId)} متاحة حالياً في مدينة ${_getCityName(_selectedCityId)}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16)),
                    ));
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                itemCount: _filteredFields.length,
                itemBuilder: (context, index) {
                  return _buildFieldCard(_filteredFields[index]);
                },
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
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          // The main content is built here, including the header
          child: _buildContent(),
        ),
      ),
    );
  }
}