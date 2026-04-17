import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://locate.graphicodeindia.com/api';
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
        headers: {'Content-Type': 'application/json'},
      );

      print('Login Response Status: ${response.statusCode}');
      print('Login Response Body: ${response.body}');

      return response;
    } catch (e) {
      print('Login Error: $e');
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

      // Add image file
      request.files.add(await http.MultipartFile.fromPath('photo', image.path));

      print('DEBUG - Sending check-in request...');
      print('DEBUG - Latitude: $lat, Longitude: $lng');

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('DEBUG - Check-in response status: ${response.statusCode}');

      return response;
    } catch (e) {
      print('DEBUG - Check-in request error: $e');
      rethrow;
    }
  }

  static Future<http.Response> checkOut(
    double lat,
    double lng,
    File image,
  ) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/check-out'),
    );
    request.headers.addAll(await getHeaders());

    request.fields['latitude'] = lat.toString();
    request.fields['longitude'] = lng.toString();

    request.files.add(await http.MultipartFile.fromPath('photo', image.path));

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
    if (location != null) request.fields['checkin_location'] = location;
    if (reason != null) request.fields['reason'] = reason;

    request.files.add(await http.MultipartFile.fromPath('photo', image.path));

    return await http.Response.fromStream(await request.send());
  }

  static Future<http.Response> outsideCheckOut(
    double lat,
    double lng,
    File image,
    String? location,
    String? reason,
  ) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/outside-check-out'),
    );
    request.headers.addAll(await getHeaders());

    request.fields['latitude'] = lat.toString();
    request.fields['longitude'] = lng.toString();
    if (location != null) request.fields['checkout_location'] = location;
    if (reason != null) request.fields['reason'] = reason;

    request.files.add(await http.MultipartFile.fromPath('photo', image.path));

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

      print('API Service - History Response Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        print('API Service - History Error Response: ${response.body}');
      }

      return response;
    } catch (e) {
      print('API Service - History Request Error: $e');
      rethrow;
    }
  }

  static Future<String> _getDeviceName() async {
    // For simplicity, using a fixed device name
    return 'flutter-app';
  }
}
