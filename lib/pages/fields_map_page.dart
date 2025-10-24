import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:custom_info_window/custom_info_window.dart';
import 'dart:ui' as ui;
import 'bookingsPages/field_details_page.dart'; // details page
import '../services/auth_service.dart'; // AuthService

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
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  final CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();

  final int radiusKm = 20;
  late LatLngBounds _cityBounds;

  final Map<String, BitmapDescriptor> _cachedIcons = {};
  String? _selectedMarkerId;

  // Icon keys
  static const String _fieldIconKey = 'field';
  static const String _fieldSelectedIconKey = 'field_selected';
  static const String _stadiumIconKey = 'stadium';
  static const String _stadiumSelectedIconKey = 'stadium_selected';
  static const String _tennisIconKey = 'tennis';
  static const String _tennisSelectedIconKey = 'tennis_selected';
  static const String _basketballIconKey = 'basketball';
  static const String _basketballSelectedIconKey = 'basketball_selected';
  static const String _padelIconKey = 'padel';
  static const String _padelSelectedIconKey = 'padel_selected';

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
      _loadFieldMarkers();
    }
  }

  bool get _canShowMap {
    return AuthService.isLoggedIn &&
        widget.initialLat != 0 &&
        widget.initialLng != 0 &&
        !widget.loading;
  }

  // Icon selection
  BitmapDescriptor? _getIconForField({
    required Map<String, dynamic> field,
    required bool isSelected,
  }) {
    final String type = (field["field_type"] ?? '').toString().toLowerCase();
    final int capacity =
        int.tryParse(field["field_capacity"]?.toString() ?? '') ?? 0;
    final bool isStadium = capacity > 14;

    switch (type) {
      case 'tennis':
        return isSelected
            ? _cachedIcons[_tennisSelectedIconKey]
            : _cachedIcons[_tennisIconKey];
      case 'basketball':
        return isSelected
            ? _cachedIcons[_basketballSelectedIconKey]
            : _cachedIcons[_basketballIconKey];
      case 'padel':
        return isSelected
            ? _cachedIcons[_padelSelectedIconKey]
            : _cachedIcons[_padelIconKey];
      default:
        if (isStadium) {
          return isSelected
              ? _cachedIcons[_stadiumSelectedIconKey]
              : _cachedIcons[_stadiumIconKey];
        } else {
          return isSelected
              ? _cachedIcons[_fieldSelectedIconKey]
              : _cachedIcons[_fieldIconKey];
        }
    }
  }

  Future<void> _loadCustomMarkers() async {
    // Football
    _cachedIcons[_fieldIconKey] =
        await _bitmapDescriptorFromAsset("assets/images/courtoFieldSprite.png", 110);
    _cachedIcons[_fieldSelectedIconKey] =
        await _bitmapDescriptorFromAsset("assets/images/courtoFieldSprite.png", 130);

    _cachedIcons[_stadiumIconKey] =
        await _bitmapDescriptorFromAsset("assets/images/courtoStadiumSprite.png", 130);
    _cachedIcons[_stadiumSelectedIconKey] =
        await _bitmapDescriptorFromAsset("assets/images/courtoStadiumSprite.png", 150);

    // Tennis
    _cachedIcons[_tennisIconKey] =
        await _bitmapDescriptorFromAsset("assets/images/courtoTennisSprite.png", 110);
    _cachedIcons[_tennisSelectedIconKey] =
        await _bitmapDescriptorFromAsset("assets/images/courtoTennisSprite.png", 130);

    // Basketball
    _cachedIcons[_basketballIconKey] =
        await _bitmapDescriptorFromAsset("assets/images/courtoBasketballSprite.png", 110);
    _cachedIcons[_basketballSelectedIconKey] =
        await _bitmapDescriptorFromAsset("assets/images/courtoBasketballSprite.png", 130);

    // Padel
    _cachedIcons[_padelIconKey] =
        await _bitmapDescriptorFromAsset("assets/images/courtoPadelSprite.png", 110);
    _cachedIcons[_padelSelectedIconKey] =
        await _bitmapDescriptorFromAsset("assets/images/courtoPadelSprite.png", 130);

    _loadFieldMarkers();
  }

  Future<BitmapDescriptor> _bitmapDescriptorFromAsset(String path, int width) async {
    final ByteData data = await rootBundle.load(path);
    final ui.Codec codec =
        await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? byteData = await fi.image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List resized = byteData!.buffer.asUint8List();
    return BitmapDescriptor.fromBytes(resized);
  }

  void _defineCityBounds() {
    final double latOffset = radiusKm / 110.574;
    final double latRad = widget.cityLat * (math.pi / 180.0);
    final double kmPerDegreeLng = 111.320 * math.cos(latRad);
    final double lngOffset = kmPerDegreeLng > 0 ? radiusKm / kmPerDegreeLng : 0.01;

    final double south = widget.cityLat - latOffset;
    final double north = widget.cityLat + latOffset;
    final double west = widget.cityLng - lngOffset;
    final double east = widget.cityLng + lngOffset;

    _cityBounds = LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }

  void _loadFieldMarkers() {
    if (_cachedIcons.isEmpty) return;

    final markers = widget.fields
        .where((f) => f["field_latitude"] != null && f["field_longitude"] != null)
        .map((field) {
      final double lat =
          double.tryParse(field["field_latitude"]?.toString() ?? '') ?? 0.0;
      final double lng =
          double.tryParse(field["field_longitude"]?.toString() ?? '') ?? 0.0;
      final String name = field["field_name"] ?? 'ملعب';

      if (lat == 0.0 && lng == 0.0) return null;

      final bool isSelected = _selectedMarkerId == name;
      final BitmapDescriptor? icon =
          _getIconForField(field: field, isSelected: isSelected);

      if (icon == null) return null;

      return Marker(
        markerId: MarkerId(name),
        position: LatLng(lat, lng),
        icon: icon,
        onTap: () => _handleMarkerTap(field),
      );
    }).whereType<Marker>().toSet();

    setState(() {
      _markers
        ..clear()
        ..addAll(markers);
    });
  }

  void _handleMarkerTap(Map<String, dynamic> field) {
    final String name = field["field_name"] ?? 'ملعب';
    final LatLng position = LatLng(
      double.tryParse(field["field_latitude"]?.toString() ?? '') ?? 0.0,
      double.tryParse(field["field_longitude"]?.toString() ?? '') ?? 0.0,
    );

    final String? oldSelectedId = _selectedMarkerId;
    if (oldSelectedId != null && oldSelectedId != name) {
      _updateSingleMarkerIcon(oldSelectedId, false);
    }

    final bool currentlySelected = _selectedMarkerId == name;
    final String? newSelectedId = currentlySelected ? null : name;

    if (!currentlySelected) _updateSingleMarkerIcon(name, true);

    setState(() => _selectedMarkerId = newSelectedId);

    if (newSelectedId != null) {
      _customInfoWindowController.addInfoWindow!(
        _buildCustomInfo(field),
        position,
      );
    } else {
      _customInfoWindowController.hideInfoWindow!();
    }
  }

  void _updateSingleMarkerIcon(String markerId, bool isSelected) {
    final field = widget.fields
        .firstWhere((f) => f["field_name"] == markerId, orElse: () => {});
    if (field.isEmpty) return;

    final BitmapDescriptor? newIcon =
        _getIconForField(field: field, isSelected: isSelected);
    if (newIcon == null) return;

    final Marker? existingMarker = _markers.firstWhere(
        (m) => m.markerId.value == markerId,
        orElse: () => null as Marker);

    if (existingMarker != null) {
      setState(() {
        _markers.remove(existingMarker);
        _markers.add(existingMarker.copyWith(iconParam: newIcon));
      });
    }
  }

  Widget _buildCustomInfo(Map<String, dynamic> field) {
    IconData fieldIcon;
    switch (field["field_type"]?.toString().toLowerCase()) {
      case "football":
        fieldIcon = Icons.sports_soccer;
        break;
      case "basketball":
        fieldIcon = Icons.sports_basketball;
        break;
      case "tennis":
        fieldIcon = Icons.sports_baseball;
        break;
      case "padel":
        fieldIcon = Icons.sports_tennis;
        break;
      default:
        fieldIcon = Icons.sports;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FieldDetailsPage(field: field),
          ),
        );
      },
      child: _AnimatedInfoWindow(
        child: Container(
          width: 240,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 6,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      field["field_name"] ?? 'ملعب',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: "Changa",
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (field["field_price"] != null)
                      Text(
                        "${field["field_price"]} / الساعة",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: "Changa",
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    fieldIcon,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    if (!_canShowMap) {
      return Scaffold(
        backgroundColor: Colors.red[50],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.map, size: 60, color: Colors.redAccent),
                SizedBox(height: 20),
                Text(
                  "يجب تسجيل الدخول ومنح صلاحية الوصول إلى الموقع لمشاهدة الملاعب.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      );
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
            buildingsEnabled: false,
            compassEnabled: false,
            trafficEnabled: false,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            cameraTargetBounds: CameraTargetBounds(_cityBounds),
            minMaxZoomPreference: const MinMaxZoomPreference(11, 17),
            onMapCreated: (controller) {
              _mapController = controller;
              _customInfoWindowController.googleMapController = controller;
            },
            onTap: (_) {
              if (_selectedMarkerId != null) {
                _customInfoWindowController.hideInfoWindow!();
                _updateSingleMarkerIcon(_selectedMarkerId!, false);
                setState(() => _selectedMarkerId = null);
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
}

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
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
