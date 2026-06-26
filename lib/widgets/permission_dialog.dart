import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class PermissionDialog extends StatefulWidget {
  final VoidCallback onAllGranted;

  const PermissionDialog({super.key, required this.onAllGranted});

  static Future<void> checkAndShow(BuildContext context, VoidCallback onAllGranted) async {
    bool locService = await Geolocator.isLocationServiceEnabled();
    bool locPerm = await Permission.location.isGranted;
    bool camPerm = await Permission.camera.isGranted;

    if (locService && locPerm && camPerm) {
      onAllGranted();
    } else {
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PermissionDialog(onAllGranted: onAllGranted),
      );
    }
  }

  @override
  State<PermissionDialog> createState() => _PermissionDialogState();
}

class _PermissionDialogState extends State<PermissionDialog> with WidgetsBindingObserver {
  bool _locService = false;
  bool _locPerm = false;
  bool _camPerm = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    bool locService = await Geolocator.isLocationServiceEnabled();
    bool locPerm = await Permission.location.isGranted;
    bool camPerm = await Permission.camera.isGranted;

    if (mounted) {
      setState(() {
        _locService = locService;
        _locPerm = locPerm;
        _camPerm = camPerm;
      });

      if (_locService && _locPerm && _camPerm) {
        Navigator.pop(context);
        widget.onAllGranted();
      }
    }
  }

  Future<void> _requestLocationService() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> _requestLocationPermission() async {
    await Permission.location.request();
    _checkPermissions();
  }

  Future<void> _requestCameraPermission() async {
    await Permission.camera.request();
    _checkPermissions();
  }

  Widget _buildPermItem(String title, String desc, bool isGranted, IconData icon, VoidCallback onGrant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isGranted ? Colors.green.withValues(alpha: 0.05) : Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isGranted ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isGranted ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isGranted ? Colors.green : Colors.red, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
              ],
            ),
          ),
          if (!isGranted)
            ElevatedButton(
              onPressed: onGrant,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9933),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                minimumSize: const Size(60, 26),
                elevation: 0,
              ),
              child: const Text("ALLOW", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            )
          else
            const Icon(Icons.check_circle, color: Colors.green),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("REQUIRED PERMISSIONS", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: 0.5)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text("Please allow these permissions to successfully mark your attendance.", style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.4)),
            const SizedBox(height: 24),
            _buildPermItem("GPS Service", "Turn on device location", _locService, Icons.gps_fixed, _requestLocationService),
            _buildPermItem("Location Access", "Allow app to see location", _locPerm, Icons.location_on_rounded, _requestLocationPermission),
            _buildPermItem("Camera Access", "Allow app to take selfie", _camPerm, Icons.camera_alt_rounded, _requestCameraPermission),
          ],
        ),
      ),
    );
  }
}
