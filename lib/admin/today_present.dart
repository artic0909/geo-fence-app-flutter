import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import 'track.dart';
import 'admin_drawer.dart';

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
    const Color bgDark = Color(0xFF121212);
    const Color cardDark = Color(0xFF1E1E1E);
    const Color goldMain = Color(0xFFD4AF37);
    const Color goldLight = Color(0xFFF9F1CC);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: const Text('PRESENT TODAY', style: TextStyle(fontWeight: FontWeight.w800, color: goldMain, letterSpacing: 1.5, fontSize: 16)),
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
      endDrawer: const AdminDrawer(currentRoute: 'TodayPresent'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: goldMain))
          : _employees.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hourglass_empty, size: 60, color: Colors.grey[800]),
                      const SizedBox(height: 15),
                      Text("No employees present yet", style: TextStyle(color: Colors.grey[500], fontSize: 16, letterSpacing: 1)),
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
                                border: Border.all(color: goldMain.withValues(alpha: 0.5)),
                              ),
                              child: const Icon(Icons.person, color: goldMain, size: 24),
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
                                  Text(emp['phone'] ?? 'N/A', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => TrackScreen(employeeId: emp['id'], employeeName: emp['name'])),
                                );
                              },
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [goldMain, Color(0xFFB58E2A)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(color: goldMain.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3)),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.my_location, size: 14, color: bgDark),
                                    SizedBox(width: 5),
                                    Text('TRACK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: bgDark, letterSpacing: 1)),
                                  ],
                                ),
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
