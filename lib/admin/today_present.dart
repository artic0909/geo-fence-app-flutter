import 'package:flutter/material.dart';

import 'dart:convert';
import '../services/api_service.dart';
import 'track.dart';

class TodayPresentScreen extends StatefulWidget {
  const TodayPresentScreen({super.key});

  @override
  State<TodayPresentScreen> createState() => _TodayPresentScreenState();
}

class _TodayPresentScreenState extends State<TodayPresentScreen> {
  bool _isLoading = true;
  List<dynamic> _employees = [];

  @override
  void initState() {
    super.initState();
    _loadPresentEmployees();
  }

  Future<void> _loadPresentEmployees() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getTodayPresent();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _employees = data['present_employees'] ?? [];
          });
        }
      } else {
        debugPrint('Error: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error loading present employees: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF2E3192);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Present Today', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _employees.isEmpty
              ? const Center(child: Text("No employees present today."))
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: _employees.length,
                  itemBuilder: (context, index) {
                    final emp = _employees[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: primaryColor.withValues(alpha: 0.1),
                              child: const Icon(Icons.person, color: primaryColor),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(emp['name'] ?? 'Unknown', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 5),
                                  Text(emp['designation'] ?? 'Employee', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                                  Text(emp['phone'] ?? 'N/A', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => TrackScreen(employeeId: emp['id'], employeeName: emp['name'])),
                                );
                              },
                              icon: const Icon(Icons.my_location, size: 16),
                              label: const Text('Track'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
