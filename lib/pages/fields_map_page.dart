import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:custom_info_window/custom_info_window.dart';
import 'dart:ui' as ui;

import 'field_details_page.dart'; // details page

class FieldsMapPage extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final double cityLat;
  final double cityLng;
  final List<Map<String, dynamic>> fields;
  final bool loading;

  const FieldsMapPage({
    super.key,
    required this.initialLat,
    required this.initialLng,
    required this.cityLat,
    required this.cityLng,
    required this.fields,
    required this.loading,
  });

  @override
  State<FieldsMapPage> createState() => _FieldsMapPageState();
}

class _FieldsMapPageState extends State<FieldsMapPage>
    with TickerProviderStateMixin {
  // ignore: unused_field
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  final CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();

  final int radiusKm = 20;
  late LatLngBounds _cityBounds;

  // Dictionary to store all icon states (Field, Stadium) to avoid reloading
  final Map<String, BitmapDescriptor> _cachedIcons = {};
  
  // Keys for standard and stadium icons
  static const String _fieldIconKey = 'field';
  static const String _fieldSelectedIconKey = 'field_selected';
  static const String _stadiumIconKey = 'stadium';
  static const String _stadiumSelectedIconKey = 'stadium_selected';

  String? _selectedMarkerId;

  @override
  void initState() {
    super.initState();
    _defineCityBounds();
    _loadCustomMarkers();
  }

  @override
  void dispose() {
    _customInfoWindowController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FieldsMapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fields != oldWidget.fields) {
      _loadFieldMarkers(); // Initial load when data changes
    }
  }

  // Helper to get the correct icon for a field based on its capacity and selected state
  BitmapDescriptor? _getIconForField({
    required Map<String, dynamic> field,
    required bool isSelected,
  }) {
    final int capacity = int.tryParse(field["field_capacity"]?.toString() ?? '') ?? 0;
    final bool isStadium = capacity > 14;

    if (isStadium) {
      return isSelected ? _cachedIcons[_stadiumSelectedIconKey] : _cachedIcons[_stadiumIconKey];
    } else {
      return isSelected ? _cachedIcons[_fieldSelectedIconKey] : _cachedIcons[_fieldIconKey];
    }
  }

  Future<void> _loadCustomMarkers() async {
    // 1. Standard Field Icons (capacity <= 14)
    _cachedIcons[_fieldIconKey] = await _bitmapDescriptorFromAsset(
      "assets/images/courtoFieldSprite.png", 110,
    );
    _cachedIcons[_fieldSelectedIconKey] = await _bitmapDescriptorFromAsset(
      "assets/images/courtoFieldSprite.png", 130,
    );

    // 2. Stadium Icons (capacity > 14)
    // NOTE: We use the same image path but for different size/purpose
    _cachedIcons[_stadiumIconKey] = await _bitmapDescriptorFromAsset(
      "assets/images/courtoStadiumSprite.png", 110,
    );
    _cachedIcons[_stadiumSelectedIconKey] = await _bitmapDescriptorFromAsset(
      "assets/images/courtoStadiumSprite.png", 140,
    );

    _loadFieldMarkers(); // Initial load after all icons are ready
  }

  Future<BitmapDescriptor> _bitmapDescriptorFromAsset(
      String path, int width) async {
    final ByteData data = await rootBundle.load(path);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? byteData =
        await fi.image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List resized = byteData!.buffer.asUint8List();
    return BitmapDescriptor.fromBytes(resized);
  }

  void _defineCityBounds() {
    final double latOffset = radiusKm / 110.574;
    final double latRad = widget.cityLat * (math.pi / 180.0);
    final double kmPerDegreeLng = 111.320 * math.cos(latRad);
    final double lngOffset =
        kmPerDegreeLng > 0 ? radiusKm / kmPerDegreeLng : 0.01;

    final double south = widget.cityLat - latOffset;
    final double north = widget.cityLat + latOffset;
    final double west = widget.cityLng - lngOffset;
    final double east = widget.cityLng + lngOffset;

    _cityBounds = LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }

  /// Initial load and full rebuild (only when data changes).
  void _loadFieldMarkers() {
    if (_cachedIcons.isEmpty) return;

    final markers = widget.fields
        .where((field) =>
            field["field_latitude"] != null &&
            field["field_longitude"] != null)
        .map((field) {
      final double lat =
          double.tryParse(field["field_latitude"]?.toString() ?? '') ?? 0.0;
      final double lng =
          double.tryParse(field["field_longitude"]?.toString() ?? '') ?? 0.0;
      final String name = field["field_name"] ?? 'ملعب';

      if (lat == 0.0 && lng == 0.0) return null;

      final bool isSelected = _selectedMarkerId == name;
      final BitmapDescriptor? icon = _getIconForField(field: field, isSelected: isSelected);

      if (icon == null) return null;

      return Marker(
        markerId: MarkerId(name),
        position: LatLng(lat, lng),
        icon: icon, // Dynamically selected icon
        onTap: () => _handleMarkerTap(field), // Use the new optimized handler
      );
    }).whereType<Marker>().toSet();

    setState(() {
      _markers
        ..clear()
        ..addAll(markers);
    });
  }
  
  // NEW: Optimized logic to only update necessary markers, fixing the buffer error.
  void _handleMarkerTap(Map<String, dynamic> field) {
    final String name = field["field_name"] ?? 'ملعب';
    final LatLng position = LatLng(
      double.tryParse(field["field_latitude"]?.toString() ?? '') ?? 0.0,
      double.tryParse(field["field_longitude"]?.toString() ?? '') ?? 0.0,
    );

    // 1. Deselect the previously selected marker
    final String? oldSelectedId = _selectedMarkerId;
    if (oldSelectedId != null && oldSelectedId != name) {
      _updateSingleMarkerIcon(oldSelectedId, false);
    }
    
    // 2. Select the new marker (or deselect the current one if tapped twice)
    final bool currentlySelected = _selectedMarkerId == name;
    final String? newSelectedId = currentlySelected ? null : name;

    if (!currentlySelected) {
      _updateSingleMarkerIcon(name, true);
    }

    // 3. Update state and info window
    setState(() {
      _selectedMarkerId = newSelectedId;
    });

    if (newSelectedId != null) {
      _customInfoWindowController.addInfoWindow!(
        _buildCustomInfo(field),
        position,
      );
    } else {
      _customInfoWindowController.hideInfoWindow!();
    }
  }

  // NEW: Function to update a single marker's icon state efficiently.
  void _updateSingleMarkerIcon(String markerId, bool isSelected) {
    final field = widget.fields.firstWhere((f) => f["field_name"] == markerId, 
        orElse: () => {});
    if (field.isEmpty) return;

    final BitmapDescriptor? newIcon = _getIconForField(field: field, isSelected: isSelected);
    if (newIcon == null) return;

    final Marker? existingMarker = _markers.firstWhere(
        (m) => m.markerId.value == markerId,
        orElse: () => null as Marker);

    if (existingMarker != null) {
      setState(() {
        _markers.remove(existingMarker);
        _markers.add(existingMarker.copyWith(
          iconParam: newIcon,
        ));
      });
    }
  }


  Widget _buildCustomInfo(Map<String, dynamic> field) {
    // Styled pop-up remains the same
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FieldDetailsPage(field: field),
          ),
        );
      },
      child: _AnimatedInfoWindow( // Provides the entry animation
        child: Container(
          width: 240,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            // Styled background: Gradient
            gradient: LinearGradient(
              colors: [Colors.red.shade600, Colors.red.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            // Styled borders: Rounded corners
            borderRadius: BorderRadius.circular(16), // Using 16 for better style
            // Styled shadow
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  field["field_name"] ?? 'ملعب',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: "Changa",
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (field["field_price"] != null)
                  Row(
                    children: [
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "${field["field_price"]} / الساعة",
                          style: const TextStyle(
                            fontFamily: "Changa",
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading || _cachedIcons.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    LatLng initialTarget = LatLng(widget.initialLat, widget.initialLng);
    if (!_pointInBounds(initialTarget, _cityBounds)) {
      initialTarget = LatLng(widget.cityLat, widget.cityLng);
    }

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: 13,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            cameraTargetBounds: CameraTargetBounds(_cityBounds),
            minMaxZoomPreference: const MinMaxZoomPreference(11, 17),
            onMapCreated: (controller) {
              _mapController = controller;
              _customInfoWindowController.googleMapController = controller;
            },
            onTap: (_) {
              // Only perform an update if a marker is currently selected
              if (_selectedMarkerId != null) {
                _customInfoWindowController.hideInfoWindow!();
                _updateSingleMarkerIcon(_selectedMarkerId!, false); // Deselect
                setState(() {
                  _selectedMarkerId = null;
                });
              }
            },
            onCameraMove: (_) => _customInfoWindowController.onCameraMove!(),
          ),
          CustomInfoWindow(
            controller: _customInfoWindowController,
            height: 110,
            width: 240,
            offset: 45,
          ),
        ],
      ),
    );
  }

  bool _pointInBounds(LatLng point, LatLngBounds bounds) {
    final double lat = point.latitude;
    final double lng = point.longitude;
    return lat >= bounds.southwest.latitude &&
        lat <= bounds.northeast.latitude &&
        lng >= bounds.southwest.longitude &&
        lng <= bounds.northeast.longitude;
  }
}

// Animated info window
class _AnimatedInfoWindow extends StatefulWidget {
  final Widget child;
  const _AnimatedInfoWindow({required this.child});

  @override
  State<_AnimatedInfoWindow> createState() => _AnimatedInfoWindowState();
}

class _AnimatedInfoWindowState extends State<_AnimatedInfoWindow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    // Provides a nice, bouncy scale-in effect
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: widget.child,
    );
  }
}