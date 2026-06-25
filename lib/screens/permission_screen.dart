import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'home_screen.dart';
import 'dart:ui';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _isLoading = false;

  Map<Permission, Map<String, dynamic>> permissions = {
    Permission.camera: {
      'title': 'Camera Access',
      'desc': 'Required for selfie verification during attendance.',
      'icon': Icons.camera_alt_rounded,
    },
    Permission.location: {
      'title': 'Location Access',
      'desc': 'Necessary to verify you are within the designated work site.',
      'icon': Icons.location_on_rounded,
    },
    Permission.locationAlways: {
      'title': 'Background Location',
      'desc': 'Allows live tracking when the app is in background or closed.',
      'icon': Icons.track_changes_rounded,
    },
    Permission.notification: {
      'title': 'Notifications',
      'desc': 'Keeps the tracking service active and sends important alerts.',
      'icon': Icons.notifications_active_rounded,
    },
    Permission.ignoreBatteryOptimizations: {
      'title': 'Battery Optimization',
      'desc': 'Set to "Unrestricted" so the system doesn\'t kill tracking.',
      'icon': Icons.battery_charging_full_rounded,
    },
  };

  Future<void> _requestAll() async {
    setState(() => _isLoading = true);
    
    try { await Permission.location.request(); } catch (e) { debugPrint(e.toString()); }
    try { await Permission.camera.request(); } catch (e) { debugPrint(e.toString()); }
    try { await Permission.notification.request(); } catch (e) { debugPrint(e.toString()); }

    // Requesting locationAlways immediately after location on Android 11+ causes an exception
    // We will skip requesting it automatically here to prevent crashes. The user can use system settings.
    
    try { await Permission.ignoreBatteryOptimizations.request(); } catch (e) { debugPrint(e.toString()); }
    
    if (mounted) {
      setState(() => _isLoading = false);
      _checkAndNavigate();
    }
  }

  Future<void> _checkAndNavigate() async {
    bool hasLocation = await Permission.location.isGranted;
    bool hasCamera = await Permission.camera.isGranted;
    
    if (hasLocation && hasCamera) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color saffron = Color(0xFFFF9933);
    const Color green = Color(0xFF138808);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Aesthetic
          Positioned.fill(
            child: CustomPaint(
              painter: FlagBannerPainter(saffron: saffron, green: green),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.white.withValues(alpha: 0.4)),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  const Icon(Icons.security_rounded, size: 60, color: saffron),
                  const SizedBox(height: 20),
                  const Text(
                    "Permissions Required",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "To ensure smooth operation and accurate tracking, we need the following access:",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(height: 30),
                  
                  Expanded(
                    child: ListView(
                      children: permissions.entries.map((entry) {
                        return _buildPermissionTile(entry.key, entry.value);
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 20),
                  // Privacy Note
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Colors.blue, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "We collect location data even when the app is closed or not in use to support live site tracking for admin monitoring.",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _requestAll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 5,
                        shadowColor: green.withValues(alpha: 0.4),
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "GRANT ALL PERMISSIONS",
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton(
                      onPressed: openAppSettings,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text(
                        "OPEN SYSTEM SETTINGS",
                        style: TextStyle(color: Color(0xFF1A1A1A), fontSize: 14, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile(Permission p, Map<String, dynamic> data) {
    return FutureBuilder<PermissionStatus>(
      future: p.status,
      builder: (context, snapshot) {
        bool isGranted = snapshot.data?.isGranted ?? false;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
            border: Border.all(color: isGranted ? Colors.green.withValues(alpha: 0.2) : Colors.transparent),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isGranted ? Colors.green : Colors.blue).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(data['icon'], color: isGranted ? Colors.green : Colors.blue, size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['title'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(data['desc'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black.withValues(alpha: 0.4))),
                  ],
                ),
              ),
              if (isGranted)
                const Icon(Icons.check_circle_rounded, color: Colors.green)
              else 
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
            ],
          ),
        );
      },
    );
  }
}

class FlagBannerPainter extends CustomPainter {
  final Color saffron, green;
  FlagBannerPainter({required this.saffron, required this.green});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    canvas.drawPath(Path()..moveTo(0, size.height * 0.2)..lineTo(size.width, 0)..lineTo(size.width, size.height * 0.15)..lineTo(0, size.height * 0.35)..close(), paint..color = saffron.withValues(alpha: 0.3));
    canvas.drawPath(Path()..moveTo(0, size.height)..lineTo(size.width, size.height * 0.8)..lineTo(size.width, size.height)..close(), paint..color = green.withValues(alpha: 0.3));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
