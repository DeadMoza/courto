import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:math' show cos, sqrt, asin;
import '../../constants.dart';
import '../bookingsPages/field_details_page.dart';

class FieldsListPage extends StatefulWidget {
  final int cityId;
  final List<Map<String, dynamic>> fields;
  final double? user_lat;
  final double? user_long;
  final bool loading;
  final String? errorMessage;

  const FieldsListPage({
    super.key,
    required this.cityId,
    required this.fields,
    required this.user_lat,
    required this.user_long,
    required this.loading,
    this.errorMessage,
  });

  @override
  State<FieldsListPage> createState() => _FieldsListPageState();
}

class _FieldsListPageState extends State<FieldsListPage> {
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _filteredFields = [];
  int? _selectedTypeId;
  int _selectedSort = 1; // 1 = closest, 2 = cheapest

  late double _userLat;
  late double _userLng;

  @override
  void initState() {
    super.initState();
    _userLat = widget.user_lat ?? 0;
    _userLng = widget.user_long ?? 0;

    _selectedTypeId = 1;
    _selectedSort = 1;

    _applyFilters();
  }

  @override
  void didUpdateWidget(covariant FieldsListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fields != widget.fields) {
      _applyFilters();
    }
  }

void _applyFilters() {
  List<Map<String, dynamic>> result = List.from(widget.fields);

  // Filter by type
  if (_selectedTypeId != null) {
    String typeName = _getTypeName(_selectedTypeId!);
    result = result.where((f) {
      return f["field_type"]?.toString() == typeName;
    }).toList();
  }

  // Sort by selected mode
  if (_selectedSort == 1) {
    // Closest
    result.sort((a, b) {
      double latA = double.tryParse(a["field_latitude"]?.toString() ?? "0") ?? 0;
      double lngA = double.tryParse(a["field_longitude"]?.toString() ?? "0") ?? 0;
      double latB = double.tryParse(b["field_latitude"]?.toString() ?? "0") ?? 0;
      double lngB = double.tryParse(b["field_longitude"]?.toString() ?? "0") ?? 0;

      double distA = _calculateDistance(_userLat, _userLng, latA, lngA);
      double distB = _calculateDistance(_userLat, _userLng, latB, lngB);
      return distA.compareTo(distB);
    });
  } else if (_selectedSort == 2) {
    // Cheapest
    result.sort((a, b) {
      double priceA = double.tryParse(a["field_price"]?.toString() ?? "0") ?? 0;
      double priceB = double.tryParse(b["field_price"]?.toString() ?? "0") ?? 0;
      return priceA.compareTo(priceB);
    });
  }

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
      default:
        return "";
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    if (lat1 == 0 || lon1 == 0 || lat2 == 0 || lon2 == 0) return double.infinity;
    const p = 0.017453292519943295; // pi / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R * asin...
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text(
                "اختر نوع الملعب",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildTypeBox(
                          icon: Icons.sports_soccer,
                          label: "كرة القدم",
                          typeId: 1,
                          selected: _selectedTypeId == 1,
                          onTap: () {
                            setDialogState(() => _selectedTypeId = 1);
                            Navigator.pop(context);
                            _applyFilters();
                          },
                        ),
                        _buildTypeBox(
                          icon: Icons.sports_basketball,
                          label: "كرة السلة",
                          typeId: 2,
                          selected: _selectedTypeId == 2,
                          onTap: () {
                            setDialogState(() => _selectedTypeId = 2);
                            Navigator.pop(context);
                            _applyFilters();
                          },
                        ),
                        _buildTypeBox(
                          icon: Icons.sports_baseball,
                          label: "تنس",
                          typeId: 3,
                          selected: _selectedTypeId == 3,
                          onTap: () {
                            setDialogState(() => _selectedTypeId = 3);
                            Navigator.pop(context);
                            _applyFilters();
                          },
                        ),
                        _buildTypeBox(
                          icon: Icons.sports_tennis,
                          label: "بادل",
                          typeId: 4,
                          selected: _selectedTypeId == 4,
                          onTap: () {
                            setDialogState(() => _selectedTypeId = 4);
                            Navigator.pop(context);
                            _applyFilters();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text("ترتيب حسب", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildSortBox(
                          label: "الأقرب",
                          selected: _selectedSort == 1,
                          onTap: () {
                            setDialogState(() => _selectedSort = 1);
                            Navigator.pop(context);
                            _applyFilters();
                          },
                        ),
                        _buildSortBox(
                          label: "الأرخص",
                          selected: _selectedSort == 2,
                          onTap: () {
                            setDialogState(() => _selectedSort = 2);
                            Navigator.pop(context);
                            _applyFilters();
                          },
                        ),
                      ],
                    ),
                  ],
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
    final url = images[0].toString();
    return url.startsWith("http")
        ? url
        : "${apiUrl.endsWith('/') ? apiUrl.substring(0, apiUrl.length - 1) : apiUrl}$url";
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
          borderRadius: BorderRadius.circular(10),
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
    final price = field["field_price"] ?? 0;
    final location = field["field_location"] ?? 'موقع غير معروف';
    final openTime = field["field_open_time"] ?? '';
    final closeTime = field["field_close_time"] ?? '';
    final capacity = field["field_capacity"] ?? 0;

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
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
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
                  Text(fieldName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("$location", style: const TextStyle(color: Colors.black54)),
                      Text("$price / الساعة", style: const TextStyle(color: Colors.red, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${AppFormat.formatArabicTime(openTime)} - ${AppFormat.formatArabicTime(closeTime)}",
                          style: const TextStyle(fontSize: 14, color: Colors.red)),
                      Row(children: [
                        const Icon(Icons.people, color: Colors.red, size: 16),
                        Text(" $capacity", style: const TextStyle(color: Colors.black)),
                      ]),
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

  Widget _buildContent() {
    if (widget.loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    if (widget.errorMessage != null) {
      return Center(child: Text('حدث خطأ: ${widget.errorMessage}',
          style: const TextStyle(color: Colors.red)));
    }

    if (_filteredFields.isEmpty) {
      return const Center(child: Text("لا توجد ملاعب متاحة حالياً."));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _filteredFields.length,
      itemBuilder: (context, index) {
        return _buildFieldCard(_filteredFields[index]);
      },
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
        child: Stack(
          children: [
            _buildContent(),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: FloatingActionButton.extended(
                  onPressed: _showFilterDialog,
                  backgroundColor: Colors.redAccent,
                  icon: const Icon(Icons.filter_list, color: Colors.white),
                  label: const Text('فلترة الملاعب',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

}
