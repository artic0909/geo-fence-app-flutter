import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/location_service.dart';
import '../services/camera_service.dart';
import '../services/api_service.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isChecking = false;
  String _status = 'Ready to check attendance';
  String _locationInfo = '';

  Future<void> _checkIn() async {
    setState(() {
      _isChecking = true;
      _status = 'Getting your location...';
      _locationInfo = '';
    });

    try {
      // Get current location
      final position = await LocationService.getCurrentLocation();

      // Update location info
      setState(() {
        _locationInfo = '📍 ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        _status = 'Location acquired. Please take a photo...';
      });

      print('DEBUG - Current Location: ${position.latitude}, ${position.longitude}');

      // Take photo
      final photo = await CameraService.takePicture();
      if (photo == null) {
        setState(() => _status = 'Photo capture cancelled');
        return;
      }

      setState(() => _status = 'Uploading your check-in...');

      // Send check-in request
      final response = await ApiService.checkIn(
        position.latitude,
        position.longitude,
        photo,
      );

      print('DEBUG - Response Status: ${response.statusCode}');
      print('DEBUG - Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _status = 'Check-in Successful! ✅';
          _locationInfo = '📊 Checked in at ${TimeOfDay.now().format(context)}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Check-in successful'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['error'] ?? errorData['message'] ?? 'Unknown error';
          setState(() => _status = 'Check-in Failed ❌');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } catch (e) {
          setState(() => _status = 'Error: ${response.body}');
        }
      }
    } catch (e) {
      print('DEBUG - Exception: $e');
      setState(() => _status = 'Connection Error 🌐');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isChecking = false);
    }
  }

  Future<void> _checkOut() async {
    setState(() {
      _isChecking = true;
      _status = 'Getting your location...';
      _locationInfo = '';
    });

    try {
      final position = await LocationService.getCurrentLocation();
      setState(() {
        _locationInfo = '📍 ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        _status = 'Location acquired. Please take a photo...';
      });

      final photo = await CameraService.takePicture();
      if (photo == null) {
        setState(() => _status = 'Photo capture cancelled');
        return;
      }

      setState(() => _status = 'Uploading your check-out...');

      final response = await ApiService.checkOut(
        position.latitude,
        position.longitude,
        photo,
      );

      if (response.statusCode == 200) {
        setState(() {
          _status = 'Check-out Successful! ✅';
          _locationInfo = '📊 Checked out at ${TimeOfDay.now().format(context)}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Check-out successful'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        final error = json.decode(response.body);
        setState(() => _status = 'Check-out Failed ❌');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error['error'] ?? 'Unknown error'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _status = 'Connection Error 🌐');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isChecking = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Attendance',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[700],
        elevation: 1,
        shadowColor: Colors.black12,
        actions: [
          IconButton(
            icon: Icon(Icons.history, color: Colors.blue[700]),
            onPressed: () => Navigator.pushNamed(context, '/history'),
            tooltip: 'Attendance History',
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.blue[700]),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Header Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue[50]!, Colors.white],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.fingerprint,
                        size: 64,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'RCPL Attendance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap below to mark your attendance',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),

              // Status Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[600],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Current Status',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getStatusColor(),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _status,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: _getStatusTextColor(),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_locationInfo.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                _locationInfo,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getStatusTextColor().withOpacity(0.8),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              if (!_isChecking) ...[
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _checkIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[600],
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.login, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Check In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _checkOut,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Check Out',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ] else
                Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Processing...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              // Help Card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.help_outline,
                            color: Colors.blue[600],
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Need Help?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildHelpItem('📍 Ensure location services are enabled'),
                      _buildHelpItem('📷 Allow camera access for photos'),
                      _buildHelpItem('🌐 Stay connected to the internet'),
                      _buildHelpItem('🎯 Be within your assigned geofence area'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 4),
          Text(
            '• ',
            style: TextStyle(color: Colors.grey[600]),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (_status.contains('Successful')) return Colors.green[50]!;
    if (_status.contains('Failed') || _status.contains('Error')) return Colors.red[50]!;
    if (_status.contains('Connection')) return Colors.orange[50]!;
    return Colors.blue[50]!;
  }

  Color _getStatusTextColor() {
    if (_status.contains('Successful')) return Colors.green[800]!;
    if (_status.contains('Failed') || _status.contains('Error')) return Colors.red[800]!;
    if (_status.contains('Connection')) return Colors.orange[800]!;
    return Colors.blue[800]!;
  }
}