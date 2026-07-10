import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../services/location_service.dart';
import '../services/camera_service.dart';
import '../services/api_service.dart';
import 'dart:convert';
import 'dart:ui';
import 'dart:math' as math;
import 'history_screen.dart';
import 'home_screen.dart';
import '../widgets/attendance_success_dialog.dart';
import '../widgets/custom_alert_dialog.dart';
import '../widgets/permission_dialog.dart';
import '../widgets/kiosk_countdown_dialog.dart';
import 'package:kiosk_mode/kiosk_mode.dart';
import 'package:phone_state/phone_state.dart';
import 'package:permission_handler/permission_handler.dart';

class OutsideAttendanceScreen extends StatefulWidget {
  const OutsideAttendanceScreen({super.key});

  @override
  State<OutsideAttendanceScreen> createState() => _OutsideAttendanceScreenState();
}

class _OutsideAttendanceScreenState extends State<OutsideAttendanceScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _isScreenLoading = true;
  bool _isChecking = false;
  bool _isSubscriptionActive = true;
  bool _isOutsideCheckedIn = false;
  String _lastActionDate = '';
  String _status = 'Ready for Outside Action';
  String _userName = 'User Name';
  String _orgName = 'Official Organization';
  LatLng? _currentLocation;
  final MapController _mapController = MapController();
  final TextEditingController _reasonController = TextEditingController();

  late AnimationController _pulseController;
  late AnimationController _refreshController;
  bool _isMapRefreshing = false;
  Timer? _trackingTimer;
  StreamSubscription<KioskMode>? _kioskSubscription;
  DateTime? _kioskRequestedTime;
  Timer? _kioskCheckTimer;
  StreamSubscription<PhoneState>? _phoneStateSubscription;
  bool _isHandlingCall = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _initializeApp();

    _kioskSubscription = watchKioskMode().listen((mode) async {
      if (mode == KioskMode.disabled && _isOutsideCheckedIn && !_isHandlingCall) {
        final prefs = await SharedPreferences.getInstance();
        final isRestricted = prefs.getBool('phone_restriction') ?? false;
        if (isRestricted && mounted && _currentLocation != null && !_isChecking) {
          debugPrint("User broke Kiosk Mode! Auto checking out (Outside)...");
          await _outsideCheckOut(isAutoTrap: true);
        }
      }
    });

    _kioskCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isOutsideCheckedIn && mounted) {
        final prefs = await SharedPreferences.getInstance();
        final isRestricted = prefs.getBool('phone_restriction') ?? false;
        
        if (isRestricted && _currentLocation != null && !_isChecking && !_isHandlingCall) {
          final mode = await getKioskMode();
          if (mode == KioskMode.disabled) {
            // 15 seconds grace period to read and accept the prompt
            final requested = _kioskRequestedTime ?? DateTime.now();
            if (DateTime.now().difference(requested).inSeconds > 15) {
              debugPrint("User denied or broke Kiosk Mode silently! Auto checking out (Outside)...");
              await _outsideCheckOut(isAutoTrap: true);
            }
          } else {
            // Reset requested time once successfully enabled
            _kioskRequestedTime = null;
          }
        }
      }
    });

    _phoneStateSubscription = PhoneState.stream.listen((event) async {
      if (event.status == PhoneStateStatus.CALL_INCOMING) {
        _isHandlingCall = true;
        await stopKioskMode();
      } else if (event.status == PhoneStateStatus.CALL_ENDED) {
        _isHandlingCall = false;
        if (_isOutsideCheckedIn) {
          final prefs = await SharedPreferences.getInstance();
          final isRestricted = prefs.getBool('phone_restriction') ?? false;
          if (isRestricted) {
            await Future.delayed(const Duration(milliseconds: 1500));
            if (!_isHandlingCall) {
              await startKioskMode();
            }
          }
        }
      }
    });
  }

  Future<void> _initializeApp() async {
    await Future.wait([
      _loadUserData(),
      _initLocation(),
    ]);
    _startTracking();
    if (mounted) {
      setState(() {
        _isScreenLoading = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _refreshController.dispose();
    _trackingTimer?.cancel();
    _kioskSubscription?.cancel();
    _phoneStateSubscription?.cancel();
    _kioskCheckTimer?.cancel();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (_isOutsideCheckedIn && !_isHandlingCall) {
        final prefs = await SharedPreferences.getInstance();
        final isRestricted = prefs.getBool('phone_restriction') ?? false;
        if (isRestricted) {
          final mode = await getKioskMode();
          if (mode == KioskMode.disabled) {
            await Future.delayed(const Duration(milliseconds: 500));
            if (!_isHandlingCall) {
              await startKioskMode();
            }
          }
        }
      }
    }
  }

  void _startTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(seconds:30), (timer) {
      _sendLocationUpdate();
    });
  }

  Future<void> _sendLocationUpdate() async {
    try {
      final pos = await LocationService.getCurrentLocation();
      await ApiService.updateLocation(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint('Outside Tracking Update Failed: $e');
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userName = prefs.getString('user_name') ?? 'User Name';
      _orgName = prefs.getString('org_name') ?? 'Official Organization';
      _isOutsideCheckedIn = prefs.getBool('is_outside_checked_in') ?? false;
      if (_isOutsideCheckedIn) {
        _status = 'You are in an active Outside Session';
      }
    });

    try {
      final response = await ApiService.getEmployeeData();
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['attendance_status'];
        final today = DateTime.now().toIso8601String().split('T')[0];
        
        setState(() {
          _isOutsideCheckedIn = status['is_outside'] ?? false;
          _isSubscriptionActive = data['admin_subscription_status'] != 'inactive';
          
          if (status['is_completed'] == true) {
            _lastActionDate = today;
          }

          if (_isOutsideCheckedIn) {
            _status = 'Outside Session Active!';
          } else if (_lastActionDate == today) {
            _status = 'Outside Attendance completed for today';
          } else {
            _status = 'Ready for Outside Action';
          }
        });
        await prefs.setBool('is_outside_checked_in', _isOutsideCheckedIn);
      }
    } catch (e) {
      debugPrint('Sync error in Outside screen: $e');
    }
  }

  Future<void> _initLocation() async {
    try {
      final position = await LocationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_currentLocation!, 16);
    } catch (e) {
      debugPrint('Location error: $e');
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

  Future<void> _toggleOutsideAttendance() async {
    await PermissionDialog.checkAndShow(context, _continueToggleOutsideAttendance);
  }

  Future<void> _continueToggleOutsideAttendance() async {
    if (_isOutsideCheckedIn) {
      await _outsideCheckOut();
    } else {
      await _outsideCheckIn();
    }
  }

  Future<String> _getAddress(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng).timeout(const Duration(seconds: 4));
      if (placemarks.isNotEmpty) {
        Placemark p = placemarks.first;
        String street = p.street ?? "";
        String subLocality = p.subLocality ?? "";
        String locality = p.locality ?? "";
        if (street.contains("Unnamed Road") || street.contains("+")) street = "";
        List<String> parts = [street, subLocality, locality].where((s) => s.isNotEmpty).toList();
        if (parts.isNotEmpty) return parts.join(", ");
      }
    } catch (e) { // ignore: empty_catches
    }

    try {
      final url = Uri.parse("https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1");
      final response = await http.get(url, headers: {'User-Agent': 'GeofenceApp/1.0'}).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String? displayName = data['display_name'];
        if (displayName != null) {
          List<String> parts = displayName.split(', ');
          if (parts.length > 3) return "${parts[0]}, ${parts[1]}, ${parts[2]}";
          return displayName;
        }
      }
    } catch (e) { // ignore: empty_catches
    }

    return "Location at ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}";
  }

  Future<void> _outsideCheckIn() async {
    if (_reasonController.text.trim().isEmpty) {
      _showError('Error: Reason is required for Check-in!');
      return;
    }

    setState(() {
      _isChecking = true;
      _status = 'Locking GPS...';
    });
    try {
      final pos = await LocationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
        _status = 'GPS Locked. Take Selfie';
      });
      _mapController.move(_currentLocation!, 17);

      final photo = await CameraService.takePicture();
      if (!mounted) return;
      if (photo == null) {
        setState(() => _status = 'Cancelled');
        return;
      }

      setState(() => _status = 'Detecting Address...');
      final String locationDesc = await _getAddress(pos.latitude, pos.longitude);
      if (!mounted) return;
      
      final prefs = await SharedPreferences.getInstance();
      final isRestricted = prefs.getBool('phone_restriction') ?? false;

      if (isRestricted) {
        await Permission.phone.request();
      }

      // 1. Enforce Kiosk Mode BEFORE API Call
      if (isRestricted && mounted) {
        setState(() => _status = 'Applying Security...');
        bool kioskEnabled = false;

        await KioskCountdownDialog.show(context, onComplete: () async {
          _kioskRequestedTime = DateTime.now();
          await startKioskMode();
        });

        // Wait for up to 15 seconds for user to accept the system prompt
        for (int i = 0; i < 15; i++) {
          await Future.delayed(const Duration(seconds: 1));
          final mode = await getKioskMode();
          if (mode == KioskMode.enabled) {
            kioskEnabled = true;
            _kioskRequestedTime = null; // Successfully enabled
            break;
          }
        }

        if (!kioskEnabled) {
          _showError('You must allow app pinning to check in outside.');
          return;
        }
      }

      setState(() => _status = 'Verifying Outside Check-in...');
      final res = await ApiService.outsideCheckIn(
        pos.latitude, pos.longitude, photo, locationDesc, _reasonController.text.trim()
      );
      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 201) {
        await prefs.setBool('is_outside_checked_in', true);
        
        setState(() {
          _isOutsideCheckedIn = true;
          _status = 'Outside Check-in Confirmed!';
          _reasonController.clear();
        });

        if (mounted) {
          AttendanceSuccessDialog.show(
            context, 
            title: "Outside Check-in", 
            message: "Your off-site duty session has started successfully."
          );
        }
      } else {
        if (isRestricted) {
          await stopKioskMode(); // Unpin if check-in fails
        }
        final error = json.decode(res.body)['error'] ?? 'Outside Check-in Rejected';
        _showError(error);
      }
    } catch (e) {
      _showError('Connection error');
    } finally {
      setState(() => _isChecking = false);
    }
  }

  Future<void> _outsideCheckOut({bool isAutoTrap = false}) async {
    setState(() {
      _isChecking = true;
      _status = isAutoTrap ? 'Violation Detected. Checking Out...' : 'Locking GPS...';
    });
    try {
      final pos = await LocationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
        _status = 'GPS Locked. Take Selfie';
      });
      _mapController.move(_currentLocation!, 17);

      File? photo;
      
      if (!isAutoTrap) {
        photo = await CameraService.takePicture();
        if (!mounted) return;
        if (photo == null) {
          setState(() => _status = 'Cancelled');
          return;
        }
      }

      setState(() => _status = 'Detecting Address...');
      final String locationDesc = await _getAddress(pos.latitude, pos.longitude);
      if (!mounted) return;

      setState(() => _status = 'Processing Outside Check-out...');
      final res = await ApiService.outsideCheckOut(
        pos.latitude, pos.longitude, photo, locationDesc, null, // No reason needed during checkout
        isAutoTrap: isAutoTrap
      );
      if (!mounted) return;

      if (res.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_outside_checked_in', false);
        
        // Ensure Kiosk Mode is stopped on Check-out
        final isRestricted = prefs.getBool('phone_restriction') ?? false;
        if (isRestricted) {
          await stopKioskMode();
        }
        
        final today = DateTime.now().toIso8601String().split('T')[0];
        setState(() {
          _isOutsideCheckedIn = false;
          _lastActionDate = today;
          _status = 'Outside Check-out Logged!';
          _reasonController.clear();
        });

        if (mounted) {
          if (isAutoTrap) {
            CustomAlertDialog.show(
              context, 
              title: "Policy Violation", 
              message: "You unpinned the app. You have been automatically checked out.",
              type: AlertType.error
            );
          } else {
            AttendanceSuccessDialog.show(
              context, 
              title: "Outside Session Ended", 
              message: "Your off-site duty has been logged. Return safely!"
            );
          }
        }
      } else {
        _showError('Outside Check-out Rejected');
      }
    } catch (e) {
      _showError('Connection error');
    } finally {
      setState(() => _isChecking = false);
    }
  }

  void _showError(String m) {
    if (mounted) {
      CustomAlertDialog.show(context, title: 'Attention', message: m, type: AlertType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color saffron = Color(0xFFFF9933);
    const Color green = Color(0xFF138808);

    if (_isScreenLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: FlagBannerPainter(saffron: saffron, green: green))),
            Positioned.fill(child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.white.withValues(alpha: 0.6)),
            )),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: saffron.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 10),
                      ]
                    ),
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final scale = 1.0 + (0.2 * math.sin(_pulseController.value * math.pi));
                        return Transform.scale(
                          scale: scale,
                          child: const Icon(Icons.location_on, color: saffron, size: 40),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text("INITIALIZING", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 2)),
                  const SizedBox(height: 8),
                  Text("Securely loading your workspace...", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black.withValues(alpha: 0.5))),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final String today = DateTime.now().toIso8601String().split('T')[0];
    final bool isCompleted = !_isOutsideCheckedIn && _lastActionDate == today;

    return PopScope(
      canPop: !_isOutsideCheckedIn && !isCompleted,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: FlagBannerPainter(saffron: saffron, green: green))),
          Positioned.fill(child: Opacity(opacity: 0.15, child: Image.asset('assets/map.png', fit: BoxFit.cover))),

          Column(
            children: [
              _buildTopBar(saffron, isCompleted),
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          _buildSatelliteMap(saffron),
                          _buildStatusRow(isCompleted),
                          const SizedBox(height: 30),
                          if (!_isOutsideCheckedIn && !isCompleted) _buildReasonInput(saffron),
                          const SizedBox(height: 10),
                          _buildAttendanceButton(Colors.orange, isCompleted),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildGuideSection(saffron),
                          const SizedBox(height: 25),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildTopBar(Color saffron, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 24, right: 24, bottom: 20),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Row(
            children: [
              if (!_isOutsideCheckedIn && !isCompleted)
                IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
                  }
                }),
              if (!_isOutsideCheckedIn && !isCompleted) const SizedBox(width: 5),
              CircleAvatar(backgroundColor: saffron.withValues(alpha: 0.1), child: Icon(Icons.person_rounded, color: saffron)),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_userName.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                    Text(_orgName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.black.withValues(alpha: 0.4))),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.history_toggle_off_rounded), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSatelliteMap(Color saffron) {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10)]),
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
                              decoration: BoxDecoration(shape: BoxShape.circle, color: saffron.withValues(alpha: 1 - _pulseController.value)),
                            ),
                          ),
                          const Icon(Icons.location_on, color: Colors.orange, size: 35),
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
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))], border: Border.all(color: Colors.white, width: 2)),
                child: RotationTransition(turns: _refreshController, child: Icon(Icons.refresh_rounded, color: saffron, size: 20)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(bool isCompleted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      color: Colors.white.withValues(alpha: 0.7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("SYSTEM STATUS", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey.shade600, letterSpacing: 1)),
                Text(_status, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF2E2E2E))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isOutsideCheckedIn && !isCompleted)
                GestureDetector(
                  onTap: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.withValues(alpha: 0.2))),
                    child: const Text("ONSITE DUTY", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.green)),
                  ),
                ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: _isOutsideCheckedIn ? Colors.orange.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: (_isOutsideCheckedIn ? Colors.orange : Colors.grey).withValues(alpha: 0.2))),
                child: Text(_isOutsideCheckedIn ? "DUTY ON" : "DUTY OFF", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _isOutsideCheckedIn ? Colors.orange : Colors.grey)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReasonInput(Color saffron) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15)],
      ),
      child: TextField(
        controller: _reasonController,
        maxLines: 2,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: "Reason for outside duty... (MANDATORY)",
          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontWeight: FontWeight.w500),
          prefixIcon: Icon(Icons.edit_note_rounded, color: saffron),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildAttendanceButton(Color orange, bool isCompleted) {
    return GestureDetector(
      onTap: (!_isSubscriptionActive || _isChecking || isCompleted) ? null : _toggleOutsideAttendance,
      child: Container(
        width: 180, height: 180,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.2), border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2)),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (!isCompleted && _isSubscriptionActive)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) => Container(
                    width: 140 + (20 * _pulseController.value),
                    height: 140 + (20 * _pulseController.value),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: (_isOutsideCheckedIn ? Colors.deepOrange : orange).withValues(alpha: 1 - _pulseController.value), width: 2)),
                  ),
                ),
              Container(
                width: 130, height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight, 
                    colors: (!_isSubscriptionActive || isCompleted) 
                        ? [Colors.grey.shade400, Colors.grey.shade600]
                        : (_isOutsideCheckedIn ? [const Color(0xFFFF5722), const Color(0xFFE64A19)] : [const Color(0xFFFFB74D), const Color(0xFFF57C00)])
                  ),
                  boxShadow: [BoxShadow(color: ((!_isSubscriptionActive || isCompleted) ? Colors.grey : (_isOutsideCheckedIn ? Colors.deepOrange : orange)).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: _isChecking 
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(!_isSubscriptionActive ? Icons.block_flipped : (isCompleted ? Icons.check_circle_rounded : (_isOutsideCheckedIn ? Icons.exit_to_app_rounded : Icons.add_location_alt_rounded)), color: Colors.white, size: 40),
                        const SizedBox(height: 8),
                        Text(!_isSubscriptionActive ? "PLAN EXPIRED" : (isCompleted ? "COMPLETED" : (_isOutsideCheckedIn ? "CHECK OUT" : "CHECK IN")), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
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
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20)], border: Border.all(color: Colors.white)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: saffron.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)), child: Icon(Icons.info_outline_rounded, color: saffron)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("OUTSIDE MODE ACTIVE", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
                const SizedBox(height: 5),
                Text("Reason is mandatory for startup. Please describe your duty context clearly.", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black.withValues(alpha: 0.5))),
              ],
            ),
          ),
        ],
      ),
    );
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
