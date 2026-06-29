import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'admin_drawer.dart';
import '../widgets/admin_loader.dart';
import 'dashboard_screen.dart';

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
    const Color bgDark = Color(0xFF121212);
    const Color cardDark = Color(0xFF1E1E1E);
    const Color goldMain = Color(0xFFD4AF37);
    const Color goldLight = Color(0xFFF9F1CC);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
      },
      child: Scaffold(
        backgroundColor: bgDark,
        appBar: AppBar(
        title: const Text('ABSENT TODAY', style: TextStyle(fontWeight: FontWeight.w800, color: goldMain, letterSpacing: 1.5, fontSize: 16)),
        backgroundColor: bgDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: goldMain),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_open, color: goldMain),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: const AdminDrawer(currentRoute: 'TodayAbsent'),
      body: _isLoading
          ? const AdminLoader()
          : _employees.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 60, color: Colors.grey[800]),
                      const SizedBox(height: 15),
                      Text("Perfect! Everyone is present.", style: TextStyle(color: Colors.grey[500], fontSize: 16, letterSpacing: 1)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  itemCount: _employees.length,
                  itemBuilder: (context, index) {
                    final emp = _employees[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: cardDark,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey[850]!, width: 1),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: bgDark,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                              ),
                              child: const Icon(Icons.person_off, color: Colors.redAccent, size: 24),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(emp['name'] ?? 'Unknown', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: goldLight)),
                                  const SizedBox(height: 4),
                                  Text(emp['designation'] ?? 'Employee', style: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w600, letterSpacing: 1)),
                                  const SizedBox(height: 2),
                                  Text('ID: ${emp['employee_id'] ?? 'N/A'}', style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(emp['phone'] ?? 'N/A', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                  if (emp['geofences'] != null && (emp['geofences'] as List).isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: (emp['geofences'] as List).map((g) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[850],
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: Colors.grey[800]!),
                                        ),
                                        child: Text(g.toString(), style: TextStyle(fontSize: 9, color: Colors.grey[400])),
                                      )).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (emp['phone'] != null && emp['phone'] != 'N/A')
                              InkWell(
                                onTap: () => _makePhoneCall(emp['phone']),
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: bgDark,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey[800]!),
                                  ),
                                  child: const Icon(Icons.call, color: Colors.greenAccent, size: 20),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
