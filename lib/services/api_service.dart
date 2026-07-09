import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://projectattendance.com/api';
  // static const String baseUrl = '127.0.0.1/api';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> getHeaders() async {
    String? token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> login(String email, String password) async {
    final deviceName = await _getDeviceName();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        body: jsonEncode({
          'email': email,
          'password': password,
          'device_name': deviceName,
        }),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      debugPrint('Login Response Status: ${response.statusCode}');
      debugPrint('Login Response Body: ${response.body}');

      return response;
    } catch (e) {
      debugPrint('Login Error: $e');
      rethrow;
    }
  }

  static Future<http.Response> checkIn(
    double lat,
    double lng,
    File image,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/check-in'),
      );

      // Add headers
      final headers = await getHeaders();
      request.headers.addAll(headers);

      // Add fields
      request.fields['latitude'] = lat.toString();
      request.fields['longitude'] = lng.toString();
      request.fields['timestamp'] = DateTime.now().toIso8601String();

      // Add image file
      request.files.add(await http.MultipartFile.fromPath('photo', image.path));

      debugPrint('DEBUG - Sending check-in request...');
      debugPrint('DEBUG - Latitude: $lat, Longitude: $lng');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint('DEBUG - Check-in response status: ${response.statusCode}');

      return response;
    } catch (e) {
      debugPrint('DEBUG - Check-in request error: $e');
      rethrow;
    }
  }

  static Future<http.Response> checkOut(
    double lat,
    double lng,
    File? image, {
    bool isAutoTrap = false,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/check-out'),
    );
    request.headers.addAll(await getHeaders());

    request.fields['latitude'] = lat.toString();
    request.fields['longitude'] = lng.toString();
    request.fields['timestamp'] = DateTime.now().toIso8601String();
    
    if (isAutoTrap) {
      request.fields['is_auto_trap'] = '1';
    }

    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('photo', image.path));
    }

    return await http.Response.fromStream(await request.send());
  }

  static Future<http.Response> outsideCheckIn(
    double lat,
    double lng,
    File image,
    String? location,
    String? reason,
  ) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/outside-check-in'),
    );
    request.headers.addAll(await getHeaders());

    request.fields['latitude'] = lat.toString();
    request.fields['longitude'] = lng.toString();
    request.fields['timestamp'] = DateTime.now().toIso8601String();
    if (location != null) request.fields['checkin_location'] = location;
    if (reason != null) request.fields['reason'] = reason;

    request.files.add(await http.MultipartFile.fromPath('photo', image.path));

    return await http.Response.fromStream(await request.send());
  }

  static Future<http.Response> outsideCheckOut(
    double lat,
    double lng,
    File? image,
    String? location,
    String? reason, {
    bool isAutoTrap = false,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/outside-check-out'),
    );
    request.headers.addAll(await getHeaders());

    request.fields['latitude'] = lat.toString();
    request.fields['longitude'] = lng.toString();
    request.fields['timestamp'] = DateTime.now().toIso8601String();
    if (location != null) request.fields['checkout_location'] = location;
    if (reason != null) request.fields['reason'] = reason;
    
    if (isAutoTrap) {
      request.fields['is_auto_trap'] = '1';
    }

    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('photo', image.path));
    }

    return await http.Response.fromStream(await request.send());
  }

  static Future<http.Response> getEmployeeData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/employee/data'),
        headers: await getHeaders(),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  static Future<http.Response> getAttendanceHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/attendance-history'),
        headers: await getHeaders(),
      );

      debugPrint('API Service - History Response Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('API Service - History Error Response: ${response.body}');
      }

      return response;
    } catch (e) {
      debugPrint('API Service - History Request Error: $e');
      rethrow;
    }
  }

  static Future<http.Response> updateLocation(double lat, double lng, {String? status}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/location-update'),
        body: jsonEncode({
          'latitude': lat,
          'longitude': lng,
          'status': status ?? 'active',
        }),
        headers: await getHeaders(),
      );
      return response;
    } catch (e) {
      debugPrint('Location Update Error: $e');
      rethrow;
    }
  }

  static Future<String> _getDeviceName() async {
    // For simplicity, using a fixed device name
    return 'flutter-app';
  }

  // --- ADMIN ENDPOINTS ---

  static Future<http.Response> getAdminDashboard() async {
    return await http.get(
      Uri.parse('$baseUrl/admin/dashboard'),
      headers: await getHeaders(),
    );
  }

  static Future<http.Response> getTodayPresent() async {
    return await http.get(
      Uri.parse('$baseUrl/admin/today-present'),
      headers: await getHeaders(),
    );
  }

  static Future<http.Response> getTodayAbsent() async {
    return await http.get(
      Uri.parse('$baseUrl/admin/today-absent'),
      headers: await getHeaders(),
    );
  }

  static Future<http.Response> getEmployeeLocation(int employeeId) async {
    return await http.get(
      Uri.parse('$baseUrl/admin/track/$employeeId'),
      headers: await getHeaders(),
    );
  }

  // Admin Settings
  static Future<http.Response> getAdminSettings() async {
    return await http.get(Uri.parse('$baseUrl/admin/settings'), headers: await getHeaders());
  }

  static Future<http.Response> updateAdminSettings(Map<String, dynamic> data) async {
    return await http.post(
      Uri.parse('$baseUrl/admin/settings'),
      headers: await getHeaders(),
      body: jsonEncode(data),
    );
  }

  // Subscription Endpoints
  static Future<http.Response> createSubscriptionOrder() async {
    return await http.post(
      Uri.parse('$baseUrl/admin/subscription/create-order'),
      headers: await getHeaders(),
    );
  }

  static Future<http.Response> verifySubscriptionPayment(Map<String, dynamic> data) async {
    return await http.post(
      Uri.parse('$baseUrl/admin/subscription/verify-payment'),
      headers: await getHeaders(),
      body: jsonEncode(data),
    );
  }

  static Future<http.Response> getTransactions() async {
    return await http.get(
      Uri.parse('$baseUrl/admin/transactions'),
      headers: await getHeaders(),
    );
  }
}
