import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:drinking_water_navigation/location.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  List<Marker> markers = [];
  List<LatLng> routePoints = [];
  bool _showDefaultBanner = false;
  late VoidCallback _trackingListener;

  @override
  void initState() {
    super.initState();
    _initMap();
    _trackingListener = () {
      if (!mounted) return;

      if (CurrentLocation.trackingNotifier.value) {
        // **TRACKING ON**: hide banner, add user marker, recenter on live coords
        setState(() => _showDefaultBanner = false);
        _addUserLocationMarker().then((_) {
          if (!mounted) return;
          final lat = CurrentLocation.latitude!;
          final lon = CurrentLocation.longitude!;
          _mapController.move(LatLng(lat, lon), 15);
        });
      } else {
        // **TRACKING OFF**: clear user marker + route, show banner, recenter to default
        setState(() {
          // remove only the red “you are here” marker (assumes user marker is a plain Icon child)
          markers.removeWhere((m) =>
          m.child is Icon &&
              (m.child as Icon).icon == Icons.person_pin_circle
          );
          routePoints.clear();
          _showDefaultBanner = true;
        });
        // recenter map to your default
        _mapController.move(
            LatLng(40.4290105, -3.73263),
            15
        );
      }
    };
    CurrentLocation.trackingNotifier.addListener(_trackingListener);

    // **NEW**: if tracking is already on, fire it once:
    if (CurrentLocation.isTrackingEnabled) {
      _trackingListener();
    }

  }

  Future<void> _initMap() async {
    // 1) Load fountains
    await loadFountainMarkers();

    // 2) Add user location marker (if permission granted)
    await _addUserLocationMarker();

    // 3) Decide if we need the default‐location banner
    if (CurrentLocation.latitude == null || CurrentLocation.longitude == null) {
      setState(() => _showDefaultBanner = true);
    }
  }

  Future<void> loadFountainMarkers() async {
    final prefs = await SharedPreferences.getInstance();
    String? dbUrl = prefs.getString('db_url');

    final database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL:
      dbUrl,
    );
    final snapshot = await database.ref().child('fountains').get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      final loaded = data.entries.map((entry) {
        final val = entry.value as Map<dynamic, dynamic>;
        final lat = (val['latitude'] as num).toDouble();
        final lon = (val['longitude'] as num).toDouble();

        return Marker(
          point: LatLng(lat, lon),
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () => _onFountainTap(LatLng(lat, lon)),
            child: Icon(Icons.opacity, size: 40, color: Colors.blue),
          ),
        );
      }).toList();

      setState(() {
        markers.addAll(loaded);
      });
    }
  }

  Future<void> _addUserLocationMarker() async {
    if (!CurrentLocation.isTrackingEnabled) return;


    try {
      // Request permission, then get position
      await Geolocator.requestPermission();
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Save to your global holder
      CurrentLocation.latitude = pos.latitude;
      CurrentLocation.longitude = pos.longitude;

      final userMarker = Marker(
        point: LatLng(pos.latitude, pos.longitude),
        width: 50,
        height: 50,
        child: Icon(Icons.person_pin_circle, size: 40, color: Colors.red),
      );

      setState(() {
        markers.add(userMarker);
      });
    } catch (e) {
      // ignore errors; we'll fall back to default center
    }
  }

  void _onFountainTap(LatLng fountain) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Drinking Water Fountain'),
        content: Text(
            'Lat: ${fountain.latitude.toStringAsFixed(4)}, Lon: ${fountain.longitude.toStringAsFixed(4)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _drawRouteTo(fountain);
            },
            child: Text('Route here'),
          ),
        ],
      ),
    );
  }

  Future<void> _drawRouteTo(LatLng dest) async {
    final startLat = CurrentLocation.latitude;
    final startLon = CurrentLocation.longitude;

    if (startLat == null || startLon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Current location unknown')),
      );
      return;
    }

    final route = await fetchRoute(
      LatLng(startLat, startLon),
      dest,
    );

    setState(() {
      routePoints = route;
    });

    // Pan/zoom to fit both points roughly
    _mapController.fitBounds(
      LatLngBounds(LatLng(startLat, startLon), dest),
      options: FitBoundsOptions(padding: EdgeInsets.all(50)),
    );
  }

  Future<List<LatLng>> fetchRoute(LatLng start, LatLng end) async {
    final url =
        'https://router.project-osrm.org/route/v1/walking/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      final coords = data['routes'][0]['geometry']['coordinates'] as List;
      return coords
          .map<LatLng>((c) => LatLng((c[1] as num).toDouble(),
          (c[0] as num).toDouble()))
          .toList();
    } else {
      throw Exception('Failed to load route');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Decide initial center
    final center = LatLng(
      CurrentLocation.latitude ?? 40.4290105,
      CurrentLocation.longitude ?? -3.73263,
    );

    return Scaffold(
      appBar: AppBar(title: Text('Map View')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 15,
              interactiveFlags: InteractiveFlag.all,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                'dev.fleaflet.flutter_map.example',
              ),
              if (routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 4.0,
                      color: Colors.purple,
                    ),
                  ],
                ),
              MarkerLayer(markers: markers),
            ],
          ),

          // One-time "default location" banner
          if (_showDefaultBanner)
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Material(
                color: Colors.yellow.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Using default center (Madrid). Waiting for GPS fix…',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
