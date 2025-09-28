import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FieldsMapPage extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final double cityLat;
  final double cityLng;
  // New required fields
  final List<Map<String, dynamic>> fields;
  final bool loading;

  const FieldsMapPage({
    super.key,
    required this.initialLat,
    required this.initialLng,
    required this.cityLat,
    required this.cityLng,
    required this.fields, // Receive fields data
    required this.loading, // Receive loading state
  });

  @override
  State<FieldsMapPage> createState() => _FieldsMapPageState();
}

class _FieldsMapPageState extends State<FieldsMapPage> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  final int radiusKm = 20;
  late LatLngBounds _cityBounds;

  @override
  void initState() {
    super.initState();
    _defineCityBounds();
    _loadFieldMarkers();
  }
  
  // Update markers when widget data changes (e.g., fields finish loading)
  @override
  void didUpdateWidget(FieldsMapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fields != oldWidget.fields) {
      _loadFieldMarkers();
    }
  }

  void _defineCityBounds() {
    // Convert km to degrees approximately
    // 1 degree latitude ≈ 110.574 km
    final double latOffset = radiusKm / 110.574;

    // 1 degree longitude ≈ 111.320 * cos(latitude_in_radians) km
    final double latRad = widget.cityLat * (math.pi / 180.0);
    final double kmPerDegreeLng = 111.320 * math.cos(latRad);

    // guard against extremely small values (just in case)
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
    // Use the fields passed from HomePage
    final markers = widget.fields.where((field) => 
        field["field_latitude"] != null && field["field_longitude"] != null
    ).map((field) {
      // Safely parse lat/lng, defaulting to 0.0 if not a number
      final double lat = double.tryParse(field["field_latitude"]?.toString() ?? '') ?? 0.0;
      final double lng = double.tryParse(field["field_longitude"]?.toString() ?? '') ?? 0.0;
      final String name = field["field_name"] ?? 'ملعب';
      
      if (lat == 0.0 && lng == 0.0) return null; // Skip invalid entries

      return Marker(
        markerId: MarkerId(name),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(title: name),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
    }).whereType<Marker>().toSet(); // Filter out nulls

    setState(() {
      _markers
        ..clear()
        ..addAll(markers);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }
    
    // Ensure the initial camera position is inside the bounds; otherwise center on city center
    LatLng initialTarget = LatLng(widget.initialLat, widget.initialLng);
    if (!_pointInBounds(initialTarget, _cityBounds)) {
      initialTarget = LatLng(widget.cityLat, widget.cityLng);
    }

    final CameraPosition initialPos = CameraPosition(
      target: initialTarget,
      zoom: 13,
    );

    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: initialPos,
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        cameraTargetBounds: CameraTargetBounds(_cityBounds), // restrict movement
        minMaxZoomPreference: const MinMaxZoomPreference(11, 17), // prevent too far zoom
        onMapCreated: (controller) => _mapController = controller,
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