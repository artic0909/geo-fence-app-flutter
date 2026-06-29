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
  String _lastUpdated = 'Loading...';
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
            _lastUpdated = 'Failed to fetch location';
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
    const Color primaryColor = Color(0xFF2E3192);

    return Scaffold(
      appBar: AppBar(
        title: Text('Tracking: ${widget.employeeName}', style: const TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
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
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.geofence',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: 80,
                      height: 80,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('Live', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const Icon(Icons.location_on, color: Colors.red, size: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            const Center(child: CircularProgressIndicator()),
            
          // Status overlay
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.history, color: primaryColor),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Last Updated', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(_lastUpdated, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ],
                    ),
                  ),
                  if (_isLoading && _currentLocation != null)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchLocation,
        backgroundColor: primaryColor,
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}
