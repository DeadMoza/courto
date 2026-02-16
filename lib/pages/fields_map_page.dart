import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:custom_info_window/custom_info_window.dart';
import 'dart:ui' as ui;
import 'package:courto/l10n/app_localizations.dart';
import 'bookingsPages/field_details_page.dart';
import '../services/auth_service.dart';

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

  // --- New/Updated State Variables ---
  final Map<String, BitmapDescriptor> _cachedIcons = {};
  final Map<String, Map<String, dynamic>> _fieldLookup = {};
  bool _iconsLoaded = false;

  String? _selectedMarkerId;
  bool _mapAvailable = true;

  final int radiusKm = 20;
  late LatLngBounds _cityBounds;

  // Icon keys
  static const String _fieldIconKey = 'field';
  static const String _fieldSelectedIconKey = 'field_selected';
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
    if (widget.fields != oldWidget.fields && _iconsLoaded) {
      _loadFieldMarkers();
    }
  }

  bool get _canShowMap {
    return AuthService.isLoggedIn &&
        widget.initialLat != 0 &&
        widget.initialLng != 0;
  }

  Future<void> _setMapStyle(GoogleMapController controller) async {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (isDarkMode) {
      final style = await rootBundle.loadString('assets/map_styles/dark_map.json');
      controller.setMapStyle(style);
    } else {
      controller.setMapStyle(null);
    }
  }

  BitmapDescriptor? _getIconForField({
    required Map<String, dynamic> field,
    required bool isSelected,
  }) {
    final String type = (field["field_type"] ?? '').toString().toLowerCase();

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
        return isSelected
            ? _cachedIcons[_fieldSelectedIconKey]
            : _cachedIcons[_fieldIconKey];
    }
  }

  Future<void> _loadCustomMarkers() async {
    try {
      _cachedIcons[_fieldIconKey] =
          await _bitmapDescriptorFromAsset("assets/images/courtoFootballSprite.png", 110);
      _cachedIcons[_fieldSelectedIconKey] =
          await _bitmapDescriptorFromAsset("assets/images/courtoFootballSprite.png", 130);

      _cachedIcons[_tennisIconKey] =
          await _bitmapDescriptorFromAsset("assets/images/courtoTennisSprite.png", 110);
      _cachedIcons[_tennisSelectedIconKey] =
          await _bitmapDescriptorFromAsset("assets/images/courtoTennisSprite.png", 130);

      _cachedIcons[_basketballIconKey] =
          await _bitmapDescriptorFromAsset("assets/images/courtoBasketballSprite.png", 110);
      _cachedIcons[_basketballSelectedIconKey] =
          await _bitmapDescriptorFromAsset("assets/images/courtoBasketballSprite.png", 130);

      _cachedIcons[_padelIconKey] =
          await _bitmapDescriptorFromAsset("assets/images/courtoPadelSprite.png", 110);
      _cachedIcons[_padelSelectedIconKey] =
          await _bitmapDescriptorFromAsset("assets/images/courtoPadelSprite.png", 130);

      if (mounted) {
        setState(() => _iconsLoaded = true);
        _loadFieldMarkers();
      }
    } catch (e) {
      // ignore: avoid_print
      print("Failed to load custom markers: $e");
      if (mounted) setState(() => _mapAvailable = false);
    }
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
    if (!_iconsLoaded) return;

    _fieldLookup.clear();

    final isEnglish = Localizations.localeOf(context).languageCode == "en";

    final markers = widget.fields
        .where((f) => f["field_latitude"] != null && f["field_longitude"] != null)
        .map((field) {
          final double lat =
              double.tryParse(field["field_latitude"]?.toString() ?? '') ?? 0.0;
          final double lng =
              double.tryParse(field["field_longitude"]?.toString() ?? '') ?? 0.0;

          final String name = isEnglish
              ? (field["field_english_name"] ?? field["field_name"] ?? 'Field')
              : (field["field_name"] ?? 'ملعب');

          final String uniqueId =
              field["field_id"]?.toString() ?? '${name}_$lat$lng';

          if (lat == 0.0 && lng == 0.0) return null;

          _fieldLookup[uniqueId] = field;

          final bool isSelected = _selectedMarkerId == uniqueId;
          final BitmapDescriptor? icon =
              _getIconForField(field: field, isSelected: isSelected);

          if (icon == null) return null;

          return Marker(
            markerId: MarkerId(uniqueId),
            position: LatLng(lat, lng),
            icon: icon,
            onTap: () => _handleMarkerTap(uniqueId),
          );
        })
        .whereType<Marker>()
        .toSet();

    setState(() {
      _markers
        ..clear()
        ..addAll(markers);
    });
  }

  void _handleMarkerTap(String markerId) {
    final Map<String, dynamic>? field = _fieldLookup[markerId];
    if (field == null) return;

    final LatLng position = LatLng(
      double.tryParse(field["field_latitude"]?.toString() ?? '') ?? 0.0,
      double.tryParse(field["field_longitude"]?.toString() ?? '') ?? 0.0,
    );

    final String? oldSelectedId = _selectedMarkerId;
    if (oldSelectedId != null && oldSelectedId != markerId) {
      _updateSingleMarkerIcon(oldSelectedId, false);
    }

    final bool currentlySelected = _selectedMarkerId == markerId;
    final String? newSelectedId = currentlySelected ? null : markerId;

    if (!currentlySelected) _updateSingleMarkerIcon(markerId, true);

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
    final field = _fieldLookup[markerId];
    if (field == null || field.isEmpty) return;

    final BitmapDescriptor? newIcon =
        _getIconForField(field: field, isSelected: isSelected);
    if (newIcon == null) return;

    final Marker? existingMarker = _markers.firstWhere(
      (m) => m.markerId.value == markerId,
      // ignore: cast_from_null_always_fails
      orElse: () => null as Marker,
    );

    if (existingMarker != null) {
      setState(() {
        _markers.remove(existingMarker);
        _markers.add(existingMarker.copyWith(iconParam: newIcon));
      });
    }
  }

  Widget _buildCustomInfo(Map<String, dynamic> field) {
    final t = AppLocalizations.of(context)!;
    final isEnglish = Localizations.localeOf(context).languageCode == "en";

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

    final double totalPrice =
        double.tryParse(field["field_calculated_total_price"]?.toString() ?? "0") ?? 0;
    final double? totalPriceAfterDiscount =
        double.tryParse(field["field_calculated_total_price_after_discount"]?.toString() ?? "0");

    final String name = isEnglish
        ? (field["field_english_name"] ?? field["field_name"] ?? "Field")
        : (field["field_name"] ?? t.fieldDefaultName);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FieldDetailsPage(field: field)),
        );
      },
      child: _AnimatedInfoWindow(
        child: Container(
          width: 240,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
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
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: "Changa",
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (field["field_has_discount"] == true)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${t.currency((totalPriceAfterDiscount ?? 0).toStringAsFixed(2))} / ${isEnglish ? "hour" : "الساعة"} |",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            totalPrice.toStringAsFixed(2),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        "${t.currency(totalPrice.toStringAsFixed(2))} / ${isEnglish ? "hour" : "الساعة"}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      )
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
                  child: Icon(fieldIcon, color: Colors.white, size: 22),
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

  Widget _buildPermissionMessage() {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map, size: 60, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 20),
              Text(
                t.mapPermissionRequired,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    if (widget.loading) {
      return Center(
        child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
      );
    }

    if (!_canShowMap) return _buildPermissionMessage();

    if (!_iconsLoaded) {
      return Center(
        child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
      );
    }

    if (!_mapAvailable) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map, size: 60, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 20),
                Text(
                  t.mapNotAvailable,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
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
            onMapCreated: (controller) async {
              try {
                _mapController = controller;
                _customInfoWindowController.googleMapController = controller;
                await _setMapStyle(controller);
              } catch (e) {
                // ignore: avoid_print
                print("Map failed to load: $e");
                setState(() => _mapAvailable = false);
              }
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
