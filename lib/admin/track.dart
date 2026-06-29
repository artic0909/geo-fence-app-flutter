import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'dart:convert';
import '../services/api_service.dart';
import 'admin_drawer.dart';
import '../widgets/admin_loader.dart';
import 'dashboard_screen.dart';

class TrackScreen extends StatefulWidget {
  final int employeeId;
  final String employeeName;

  const TrackScreen({super.key, required this.employeeId, required this.employeeName});

  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  String _lastUpdated = 'Fetching...';
  bool _isLoading = true;
  Timer? _timer;

  String _attendanceType = 'none';
  Map<String, dynamic>? _geofence;
  String? _checkinLocation;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchLocation();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    try {
      final response = await ApiService.getEmployeeLocation(widget.employeeId);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final lat = double.parse(data['latitude'].toString());
        final lng = double.parse(data['longitude'].toString());

        if (mounted) {
          setState(() {
            _currentLocation = LatLng(lat, lng);
            _lastUpdated = data['last_updated'] ?? 'Just now';
            _attendanceType = data['attendance_type'] ?? 'none';
            _geofence = data['geofence'];
            _checkinLocation = data['checkin_location'];
            _isLoading = false;
          });
          _mapController.move(_currentLocation!, 16.0);
        }
      } else {
        if (mounted) {
          setState(() {
            _lastUpdated = 'Offline';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lastUpdated = 'Error';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF121212);
    const Color cardDark = Color(0xFF1E1E1E);
    const Color goldMain = Color(0xFFD4AF37);
    const Color goldLight = Color(0xFFF9F1CC);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
      },
      child: Scaffold(
        backgroundColor: bgDark,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('LIVE TRACKING', style: TextStyle(fontWeight: FontWeight.w800, color: goldMain, letterSpacing: 1.5, fontSize: 12)),
              Text(widget.employeeName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600, color: goldLight, fontSize: 16)),
            ],
          ),
          backgroundColor: bgDark,
          elevation: 0,
          iconTheme: const IconThemeData(color: goldMain),
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_open, color: goldMain),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          ],
        ),
        endDrawer: const AdminDrawer(currentRoute: 'Track'),
        body: Stack(
          children: [
            if (_currentLocation != null)
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentLocation!,
                  initialZoom: 16.0,
                ),
                children: [
                  TileLayer(
                    // Dark themed OpenStreetMap tiles
                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                    userAgentPackageName: 'com.example.geofence',
                  ),
                  if (_geofence != null)
                    CircleLayer(
                      circles: [
                        if (_geofence!['tracking_radius'] != null)
                          CircleMarker(
                            point: LatLng(
                              double.parse(_geofence!['latitude'].toString()),
                              double.parse(_geofence!['longitude'].toString()),
                            ),
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderColor: Colors.orange.withValues(alpha: 0.5),
                            borderStrokeWidth: 2,
                            radius: double.parse(_geofence!['tracking_radius'].toString()),
                            useRadiusInMeter: true,
                          ),
                        CircleMarker(
                          point: LatLng(
                            double.parse(_geofence!['latitude'].toString()),
                            double.parse(_geofence!['longitude'].toString()),
                          ),
                          color: Colors.green.withValues(alpha: 0.15),
                          borderColor: Colors.green.withValues(alpha: 0.8),
                          borderStrokeWidth: 2,
                          radius: double.parse(_geofence!['radius'].toString()),
                          useRadiusInMeter: true,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentLocation!,
                        width: 100,
                        height: 100,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: bgDark,
                                border: Border.all(color: goldMain),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.employeeName.split(' ')[0],
                                style: const TextStyle(color: goldMain, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const Icon(Icons.location_on, color: goldMain, size: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              const AdminLoader(message: "Locating agent..."),
              
            // Status overlay
            if (_currentLocation != null)
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardDark.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: goldMain.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_attendanceType == 'onsite' && _geofence != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.greenAccent, size: 24),
                            const SizedBox(width: 10),
                            Expanded(child: Text('Checked In: ${_geofence!['name']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text('Radius: ${_geofence!['radius']}m | Track Area: ${_geofence!['tracking_radius'] ?? 'Disabled'}m', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      ] else if (_attendanceType == 'outside') ...[
                        Row(
                          children: [
                            const Icon(Icons.location_off, color: Colors.orangeAccent, size: 24),
                            const SizedBox(width: 10),
                            const Expanded(child: Text('Checked In Outside', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(_checkinLocation ?? 'Location not recorded', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      ] else ...[
                        Row(
                          children: [
                            const Icon(Icons.not_interested, color: Colors.redAccent, size: 24),
                            const SizedBox(width: 10),
                            const Expanded(child: Text('Not Checked In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          ],
                        ),
                      ],
                      const Divider(color: Colors.white24, height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Last Signal:', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                          Row(
                            children: [
                              Text(_lastUpdated, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: goldLight)),
                              if (_isLoading) ...[
                                const SizedBox(width: 10),
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: goldMain),
                                ),
                              ]
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 150), // Adjusted so it doesn't overlap the overlay
          child: FloatingActionButton(
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchLocation();
            },
            backgroundColor: goldMain,
            foregroundColor: bgDark,
            child: const Icon(Icons.my_location),
          ),
        ),
      ),
    );
  }
}
