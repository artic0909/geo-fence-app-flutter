import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'admin_drawer.dart';

class TodayAbsentScreen extends StatefulWidget {
  const TodayAbsentScreen({super.key});

  @override
  State<TodayAbsentScreen> createState() => _TodayAbsentScreenState();
}

class _TodayAbsentScreenState extends State<TodayAbsentScreen> {
  bool _isLoading = true;
  List<dynamic> _employees = [];

  @override
  void initState() {
    super.initState();
    _loadAbsentEmployees();
  }

  Future<void> _loadAbsentEmployees() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getTodayAbsent();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _employees = data['absent_employees'] ?? [];
          });
        }
      } else {
        debugPrint('Error: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error loading absent employees: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch phone dialer.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absent Today', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red[600],
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
      endDrawer: const AdminDrawer(currentRoute: 'TodayAbsent'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _employees.isEmpty
              ? const Center(child: Text("All employees are present today!"))
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
                              backgroundColor: Colors.red.withValues(alpha: 0.1),
                              child: const Icon(Icons.person_off, color: Colors.red),
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
                            if (emp['phone'] != null && emp['phone'] != 'N/A')
                              IconButton(
                                icon: const Icon(Icons.call, color: Colors.green),
                                onPressed: () => _makePhoneCall(emp['phone']),
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
