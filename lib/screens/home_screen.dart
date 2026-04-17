import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/camera_service.dart';
import '../services/api_service.dart';
import 'dart:convert';
import 'dart:ui';
import 'login_screen.dart';
import 'outside_attendance_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isChecking = false;
  bool _isCheckedIn = false;
  String _status = 'Ready for action';
  String _userName = 'User Name';
  String _orgName = 'Ranihati Construction Private Limited';
  String _lastActionDate = ''; 
  LatLng? _currentLocation;
  final MapController _mapController = MapController();

  late AnimationController _pulseController;
  late AnimationController _refreshController;
  bool _isMapRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initLocation();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Initial load from local storage
    setState(() {
      _userName = prefs.getString('user_name') ?? 'User Name';
      _orgName = prefs.getString('org_name') ?? 'Official Organization';
      _isCheckedIn = prefs.getBool('is_checked_in') ?? false;
      _lastActionDate = prefs.getString('last_action_date') ?? '';
    });

    // Proactive Sync with Server
    try {
      final response = await ApiService.getEmployeeData();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['attendance_status'];
        final today = DateTime.now().toIso8601String().split('T')[0];

        setState(() {
          _userName = data['employee_name'] ?? _userName;
          _isCheckedIn = status['is_checked_in'] ?? false;
          if (status['is_completed'] == true) {
            _lastActionDate = today;
          }
          
          if (_isCheckedIn) {
            _status = 'You are currently on duty';
          } else if (_lastActionDate == today) {
            _status = 'Attendance completed for today';
          } else {
            _status = 'Ready for action';
          }
        });

        // Sync back to local storage
        await prefs.setBool('is_checked_in', _isCheckedIn);
        await prefs.setString('last_action_date', _lastActionDate);
      }
    } catch (e) {
      print('Sync error: $e');
    }
  }

  Future<void> _initLocation() async {
    try {
      final position = await LocationService.getCurrentLocation();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_currentLocation!, 16);
    } catch (e) {
      print('Location error: $e');
    }
  }

  Future<void> _refreshMap() async {
    if (_isMapRefreshing) return;
    setState(() => _isMapRefreshing = true);
    _refreshController.repeat();
    
    try {
      await Future.wait([_initLocation(), _loadUserData()]);
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      _refreshController.stop();
      if (mounted) setState(() => _isMapRefreshing = false);
    }
  }

  Future<void> _toggleAttendance() async {
    if (_isCheckedIn) {
      await _checkOut();
    } else {
      final today = DateTime.now().toIso8601String().split('T')[0];
      if (_lastActionDate == today) {
        _showError('You have already completed attendance for today.');
        return;
      }
      await _checkIn();
    }
  }

  Future<void> _checkIn() async {
    setState(() {
      _isChecking = true;
      _status = 'Locking GPS...';
    });
    try {
      final pos = await LocationService.getCurrentLocation();
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
        _status = 'GPS Locked. Take Selfie';
      });
      _mapController.move(_currentLocation!, 17);

      final photo = await CameraService.takePicture();
      if (photo == null) {
        setState(() => _status = 'Cancelled');
        return;
      }

      setState(() => _status = 'Verifying Check-in...');
      final res = await ApiService.checkIn(pos.latitude, pos.longitude, photo);

      if (res.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final today = DateTime.now().toIso8601String().split('T')[0];
        await prefs.setBool('is_checked_in', true);
        await prefs.setString('last_action_date', today);
        setState(() {
          _isCheckedIn = true;
          _lastActionDate = today;
          _status = 'Check-in Confirmed! ✅';
        });
      } else {
        final error = json.decode(res.body)['error'] ?? 'Check-in Rejected';
        _showError(error);
      }
    } catch (e) {
      _showError('Connection error');
    } finally {
      setState(() => _isChecking = false);
    }
  }

  Future<void> _checkOut() async {
    setState(() {
      _isChecking = true;
      _status = 'Locking GPS...';
    });
    try {
      final pos = await LocationService.getCurrentLocation();
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
        _status = 'GPS Locked. Take Selfie';
      });
      _mapController.move(_currentLocation!, 17);

      final photo = await CameraService.takePicture();
      if (photo == null) {
        setState(() => _status = 'Cancelled');
        return;
      }

      setState(() => _status = 'Processing Check-out...');
      final res = await ApiService.checkOut(pos.latitude, pos.longitude, photo);

      if (res.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final today = DateTime.now().toIso8601String().split('T')[0];
        await prefs.setBool('is_checked_in', false);
        await prefs.setString('last_action_date', today);
        setState(() {
          _isCheckedIn = false;
          _lastActionDate = today;
          _status = 'Check-out Logged! ✅';
        });
      } else {
        final error = json.decode(res.body)['error'] ?? 'Check-out Rejected';
        _showError(error);
      }
    } catch (e) {
      _showError('Connection error');
    } finally {
      setState(() => _isChecking = false);
    }
  }

  void _showError(String m) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    const Color saffron = Color(0xFFFF9933);
    const Color green = Color(0xFF138808);
    final String today = DateTime.now().toIso8601String().split('T')[0];
    final bool isCompleted = !_isCheckedIn && _lastActionDate == today;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: FlagBannerPainter(saffron: saffron, green: green))),
          Positioned.fill(child: Opacity(opacity: 0.15, child: Image.asset('assets/map.png', fit: BoxFit.cover))),

          Column(
            children: [
              _buildTopBar(saffron),
              _buildSatelliteMap(saffron),
              _buildStatusRow(),
              Expanded(child: Center(child: _buildAttendanceButton(green, isCompleted))),
              _buildGuideSection(saffron),
              const SizedBox(height: 25),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(Color saffron) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 24, right: 24, bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: saffron.withOpacity(0.1), child: Icon(Icons.person_rounded, color: saffron)),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_userName.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                    Text(_orgName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black.withOpacity(0.4))),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.history_toggle_off_rounded), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()))),
              IconButton(icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent), onPressed: _logout),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSatelliteMap(Color saffron) {
    return Container(
      height: 320,
      width: double.infinity,
      decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)]),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(initialCenter: _currentLocation ?? const LatLng(22.5726, 88.3639), initialZoom: 16),
            children: [
              TileLayer(urlTemplate: 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}', userAgentPackageName: 'com.palgeo.app'),
              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: 60, height: 60,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) => Container(
                              width: 30 + (30 * _pulseController.value),
                              height: 30 + (30 * _pulseController.value),
                              decoration: BoxDecoration(shape: BoxShape.circle, color: saffron.withOpacity(1 - _pulseController.value)),
                            ),
                          ),
                          const Icon(Icons.location_on, color: Colors.red, size: 35),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 15, right: 15,
            child: GestureDetector(
              onTap: _refreshMap,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))], border: Border.all(color: Colors.white, width: 2)),
                child: RotationTransition(turns: _refreshController, child: Icon(Icons.refresh_rounded, color: saffron, size: 20)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      color: Colors.white.withOpacity(0.7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("SYSTEM STATUS", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey.shade600, letterSpacing: 1)),
              Text(_status, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF2E2E2E))),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isCheckedIn && _lastActionDate != DateTime.now().toIso8601String().split('T')[0])
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const OutsideAttendanceScreen())),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.orange.withOpacity(0.2))),
                    child: const Text("OUTSIDE ATTENDANCE", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.orange)),
                  ),
                ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isCheckedIn ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: (_isCheckedIn ? Colors.red : Colors.green).withOpacity(0.2)),
                ),
                child: Text(_isCheckedIn ? "ON DUTY" : "OFF DUTY", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _isCheckedIn ? Colors.red : Colors.green)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceButton(Color green, bool isCompleted) {
    return GestureDetector(
      onTap: (_isChecking || isCompleted) ? null : _toggleAttendance,
      child: Container(
        width: 200, height: 200,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.2), border: Border.all(color: Colors.white.withOpacity(0.5), width: 2)),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (!isCompleted)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) => Container(
                    width: 160 + (20 * _pulseController.value),
                    height: 160 + (20 * _pulseController.value),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: (_isCheckedIn ? Colors.red : green).withOpacity(1 - _pulseController.value), width: 2)),
                  ),
                ),
              Container(
                width: 150, height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: isCompleted 
                        ? [Colors.grey.shade400, Colors.grey.shade600]
                        : (_isCheckedIn ? [const Color(0xFFFF5252), const Color(0xFFD32F2F)] : [const Color(0xFF66BB6A), const Color(0xFF388E3C)]),
                  ),
                  boxShadow: [BoxShadow(color: (isCompleted ? Colors.grey : (_isCheckedIn ? Colors.red : green)).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: _isChecking
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isCompleted ? Icons.check_circle_rounded : (_isCheckedIn ? Icons.logout_rounded : Icons.fingerprint_rounded), color: Colors.white, size: 50),
                          const SizedBox(height: 10),
                          Text(isCompleted ? "COMPLETED" : (_isCheckedIn ? "CHECK OUT" : "MARK PRESENT"), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideSection(Color saffron) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)], border: Border.all(color: Colors.white)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: saffron.withOpacity(0.1), borderRadius: BorderRadius.circular(15)), child: Icon(Icons.verified_user_rounded, color: saffron)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("GEOFENCE MODE ACTIVE", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 5),
                Text("Ensure you are within the geo-fence and your face is fully visible for the selfie check.", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black.withOpacity(0.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }
}

class FlagBannerPainter extends CustomPainter {
  final Color saffron, green;
  FlagBannerPainter({required this.saffron, required this.green});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    canvas.drawPath(Path()..moveTo(0, 0)..lineTo(size.width * 0.7, 0)..lineTo(0, size.height * 0.45)..close(), paint..color = saffron);
    canvas.drawPath(Path()..moveTo(size.width, size.height)..lineTo(size.width * 0.3, size.height)..lineTo(size.width, size.height * 0.55)..close(), paint..color = green);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
