import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'dart:convert';
import '../services/api_service.dart';
import 'admin_drawer.dart';

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
        final lat = data['latitude'] as double;
        final lng = data['longitude'] as double;

        if (mounted) {
          setState(() {
            _currentLocation = LatLng(lat, lng);
            _lastUpdated = data['last_updated'] ?? 'Just now';
            _isLoading = false;
          });
          _mapController.move(_currentLocation!, 16.0);
        }
      } else {
        if (mounted) {
          setState(() {
            _lastUpdated = 'Location unavailable';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lastUpdated = 'Network error';
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

    return Scaffold(
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
                              boxShadow: [
                                BoxShadow(color: goldMain.withValues(alpha: 0.3), blurRadius: 10),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                                SizedBox(width: 5),
                                Text('LIVE', style: TextStyle(color: goldMain, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              ],
                            ),
                          ),
                          const Icon(Icons.location_on, color: goldMain, size: 45),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            const Center(child: CircularProgressIndicator(color: goldMain)),
            
          // Status overlay
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: goldMain.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 15, offset: const Offset(0, 10)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: bgDark,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: const Icon(Icons.update, color: goldMain, size: 20),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LAST UPDATED', style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                        const SizedBox(height: 4),
                        Text(_lastUpdated, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: goldLight)),
                      ],
                    ),
                  ),
                  if (_isLoading && _currentLocation != null)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: goldMain),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120),
        child: FloatingActionButton(
          onPressed: _fetchLocation,
          backgroundColor: goldMain,
          foregroundColor: bgDark,
          child: const Icon(Icons.my_location),
        ),
      ),
    );
  }
}
