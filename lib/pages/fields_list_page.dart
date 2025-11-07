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
  });

  @override
  State<FieldsListPage> createState() => _FieldsListPageState();
}

class _FieldsListPageState extends State<FieldsListPage> {
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _filteredFields = [];
  int _selectedTypeId = 1; // Default to Football
  int _selectedSort = 1; // 1 = closest, 2 = cheapest

  // New State for City Filter
  
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

    _applyFilters();
  }

  @override
  void didUpdateWidget(covariant FieldsListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.fields != widget.fields || oldWidget.cityId != widget.cityId) {
     
      if (oldWidget.cityId != widget.cityId) {
        _selectedCityId = widget.cityId;
      }
      _applyFilters();
    }
  }

  // API Call to fetch Cities



  void _applyFilters() {
    List<Map<String, dynamic>> result = List.from(widget.fields);

    // 1. Pre-calculate and store distance (Performance optimization)
    result = result.map((f) {
      double lat = double.tryParse(f["field_latitude"]?.toString() ?? "0") ?? 0;
      double lng = double.tryParse(f["field_longitude"]?.toString() ?? "0") ?? 0;
      double distance = _calculateDistance(_userLat, _userLng, lat, lng);

      return {
        ...f,
        'calculated_distance': distance,
        'calculated_total_price': double.tryParse(f["field_calculated_total_price"]?.toString() ?? "0") ?? 0,
      };

    }).toList();

    // 2. Filter by type
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
      default: return "";
    }
  }

  String _getTypeLabel(int typeId) {
    switch (typeId) {
      case 1: return "كرة القدم";
      case 2: return "كرة السلة";
      case 3: return "تنس";
      case 4: return "بادل";
      default: return "الكل";
    }
  }

  String _getCityName(int cityId) {
    return widget.cities.firstWhere(
      (city) => city['city_id'] == cityId,
      orElse: () => {'city_name': 'المدينة غير معروفة'},
    )['city_name'] as String;
  }

  // Haversine formula remains the same
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
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
              content: SingleChildScrollView(
                // Ensure scrollability and center the content
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center, // Center columns content
                    children: [
                      // --- City Filter Section ---
                      const Text("اختر المدينة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      if (widget.cities.isEmpty)
                        const Center(child: Text("جاري تحميل المدن...", style: TextStyle(color: Colors.grey)))
                      else
                        Wrap(
                          alignment: WrapAlignment.start, 
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.cities.map((city) {
                            final cityId = city['city_id'] as int;
                            final cityName = city['city_name'] as String;
                            return _buildCityChip(
                              label: cityName,
                              cityId: cityId,
                              selected: tempSelectedCityId == cityId,
                              onTap: () {
                                setState(() => _selectedCityId = cityId);
                                Navigator.pop(context);
                                widget.onCityChanged(cityId); 
                              },
                            );
                          }).toList(),

                        ),

                      const SizedBox(height: 5),
                      const Divider(),

                      // --- Field Type Filter Section ---
                      const Text("اختر نوع الملعب", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center, // Centering the type boxes
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildTypeBox(icon: Icons.sports_soccer, label: "كرة القدم", typeId: 1, selected: tempSelectedTypeId == 1, onTap: () {
                            // TYPE CHANGE: Update dialog state, main state, close dialog, apply filter
                            setDialogState(() => tempSelectedTypeId = 1);
                            setState(() => _selectedTypeId = tempSelectedTypeId);
                            Navigator.pop(context);
                            _applyFilters();
                          }),
                          _buildTypeBox(icon: Icons.sports_basketball, label: "كرة السلة", typeId: 2, selected: tempSelectedTypeId == 2, onTap: () {
                            setDialogState(() => tempSelectedTypeId = 2);
                            setState(() => _selectedTypeId = tempSelectedTypeId);
                            Navigator.pop(context);
                            _applyFilters();
                          }),
                          _buildTypeBox(icon: Icons.sports_baseball, label: "تنس", typeId: 3, selected: tempSelectedTypeId == 3, onTap: () {
                            setDialogState(() => tempSelectedTypeId = 3);
                            setState(() => _selectedTypeId = tempSelectedTypeId);
                            Navigator.pop(context);
                            _applyFilters();
                          }),
                          _buildTypeBox(icon: Icons.sports_tennis, label: "بادل", typeId: 4, selected: tempSelectedTypeId == 4, onTap: () {
                            setDialogState(() => tempSelectedTypeId = 4);
                            setState(() => _selectedTypeId = tempSelectedTypeId);
                            Navigator.pop(context);
                            _applyFilters();
                          }),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Divider(),

                      // --- Sorting Section ---
                      const Text("ترتيب حسب", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSortBox(label: "الأقرب", selected: tempSelectedSort == 1, onTap: () {
                            // SORT CHANGE: Update dialog state, main state, close dialog, apply filter
                            setDialogState(() => tempSelectedSort = 1);
                            setState(() => _selectedSort = tempSelectedSort);
                            Navigator.pop(context);
                            _applyFilters();
                          }),
                          _buildSortBox(label: "الأرخص", selected: tempSelectedSort == 2, onTap: () {
                            setDialogState(() => tempSelectedSort = 2);
                            setState(() => _selectedSort = tempSelectedSort);
                            Navigator.pop(context);
                            _applyFilters();
                          }),
                        ],
                      ),
                    ],
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
  // Disable non-Tripoli cities
  bool isTripoli = label == 'طرابلس' || label.toLowerCase() == 'tripoli';
  bool isDisabled = !isTripoli;

  return GestureDetector(
    onTap: isDisabled ? null : onTap, // disable tap if not Tripoli
    child: Opacity(
      opacity: isDisabled ? 0.4 : 1.0, // dim other cities
      child: Chip(
        label: Text(
          label,
          style: TextStyle(color: selected ? Colors.white : Colors.black87),
        ),
        backgroundColor:
            selected ? Colors.redAccent : Colors.grey[200],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
          side: BorderSide(
            color: selected ? Colors.red : Colors.grey[300]!,
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
          color: selected ? Colors.red[100] : Colors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: selected ? Colors.redAccent : Colors.grey[300]!,
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
            Icon(icon, color: selected ? Colors.redAccent : Colors.red, size: 40),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: selected ? Colors.redAccent : Colors.black)),
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
            color: selected ? Colors.redAccent : Colors.grey[300]!,
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
          child: Text(label, style: TextStyle(color: selected ? Colors.redAccent : Colors.black)),
        ),
      ),
    );
  }

  Widget _buildFieldCard(Map<String, dynamic> field) {
    final imageUrl = getFirstImageUrl(field["field_images"] ?? []);
    final fieldName = field["field_name"] ?? 'ملعب غير مسمى';
    final totalPrice = field['calculated_total_price'] as double;
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
          color: Colors.white,
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
                  child: const Center(
                    child: Icon(Icons.sports_soccer, size: 40, color: Colors.red),
                  ),
                ),
              ),
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
                          const Icon(Icons.location_on, color: Colors.redAccent, size: 16),
                          const SizedBox(width: 4),
                          Text(distanceText, style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                      Text("د.ل. ${totalPrice.toStringAsFixed(2)} / الساعة", style: const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        // AppFormat is assumed to be available
                        "${AppFormat.formatArabicTime(openTime)} - ${AppFormat.formatArabicTime(closeTime)}",
                        style: const TextStyle(fontSize: 14, color: Colors.red),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.people, color: Colors.red, size: 16),
                          Text(" $capacity", style: const TextStyle(color: Colors.black)),
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
    String sortLabel = _selectedSort == 1 ? "الأقرب" : "الأرخص";
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
              child: Row( // Use Row for an inline, scrollable list of chips
                children: [
                  // Added GestureDetector to open filter dialog
                  GestureDetector(
                    onTap: _showFilterDialog,
                    child: Chip(
                      label: Text("المدينة: ${cityName}", style: const TextStyle(color: Colors.white)),
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Added GestureDetector to open filter dialog
                  GestureDetector(
                    onTap: _showFilterDialog,
                    child: Chip(
                      label: Text("النوع: ${typeLabel}", style: const TextStyle(color: Colors.black87)),
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                        side: BorderSide(color: Colors.grey[300]!, width: 1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Added GestureDetector to open filter dialog
                  GestureDetector(
                    onTap: _showFilterDialog,
                    child: Chip(
                      label: Text("ترتيب: ${sortLabel}", style: const TextStyle(color: Colors.black87)),
                      backgroundColor: Colors.white,
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
            icon: const Icon(Icons.filter_list, color: Colors.redAccent),
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
                return const Center(child: CircularProgressIndicator(color: Colors.red));
              }

              if (widget.errorMessage != null) {
                return Center(
                    child: Text('حدث خطأ: ${widget.errorMessage}',
                        style: const TextStyle(color: Colors.red)));
              }

              if (_filteredFields.isEmpty) {
                return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                          "لا توجد ملاعب متاحة حالياً لنوع '${_getTypeLabel(_selectedTypeId)}' في مدينة '${_getCityName(_selectedCityId)}'.",
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
        backgroundColor: Colors.red[50],
        body: SafeArea(
          // The main content is built here, including the header
          child: _buildContent(),
        ),
      ),
    );
  }
}