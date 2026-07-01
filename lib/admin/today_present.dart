import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import 'track.dart';
import 'admin_drawer.dart';
import '../widgets/admin_loader.dart';

class TodayPresentScreen extends StatefulWidget {
  const TodayPresentScreen({super.key});

  @override
  State<TodayPresentScreen> createState() => _TodayPresentScreenState();
}

class _TodayPresentScreenState extends State<TodayPresentScreen> {
  bool _isLoading = true;
  List<dynamic> _employees = [];
  List<dynamic> _filteredEmployees = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPresentEmployees();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredEmployees = _employees;
      } else {
        _filteredEmployees = _employees.where((emp) {
          final name = (emp['name'] ?? '').toLowerCase();
          final email = (emp['email'] ?? '').toLowerCase();
          return name.contains(query) || email.contains(query);
        }).toList();
      }
    });
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
            _filteredEmployees = _employees;
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
          automaticallyImplyLeading: false,
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
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by employee name or email...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.search, color: goldMain),
                  filled: true,
                  fillColor: cardDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: goldMain, width: 1.5),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const AdminLoader()
                  : _filteredEmployees.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off, size: 60, color: Colors.grey[800]),
                              const SizedBox(height: 15),
                              Text("No employees found", style: TextStyle(color: Colors.grey[500], fontSize: 16, letterSpacing: 1)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          itemCount: _filteredEmployees.length,
                          itemBuilder: (context, index) {
                            final emp = _filteredEmployees[index];
                            final dynamic rawPrivacy = emp['is_privacy_violation'];
                            final bool isPrivacyViolation = rawPrivacy == true || rawPrivacy == 1 || rawPrivacy == '1';
                            final bool isOutside = (emp['type'] ?? '') == 'Outside';
                            final bool isCheckedOut = emp['check_out'] != null;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: cardDark,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: isPrivacyViolation ? Colors.redAccent.withValues(alpha: 0.5) : Colors.grey[850]!,
                                  width: isPrivacyViolation ? 1.5 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isPrivacyViolation ? Colors.redAccent.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header: Badges & Employee Name
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: isOutside ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                                                      border: Border.all(color: isOutside ? Colors.orange : Colors.green),
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Text(
                                                      emp['type'] ?? 'Normal',
                                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isOutside ? Colors.orange : Colors.green),
                                                    ),
                                                  ),
                                                  if (isPrivacyViolation)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red.withValues(alpha: 0.1),
                                                        border: Border.all(color: Colors.red),
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      child: const Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.warning_amber_rounded, size: 12, color: Colors.red),
                                                          SizedBox(width: 4),
                                                          Text(
                                                            'Privacy Violation',
                                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Text(emp['name'] ?? 'Unknown', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: goldLight)),
                                              const SizedBox(height: 2),
                                              Text(emp['email'] ?? 'N/A', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                              const SizedBox(height: 2),
                                              Text('ID: ${emp['employee_id'] ?? 'N/A'}', style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                        // Action Button / Duty Completed
                                        if (isCheckedOut)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[800],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text('Duty Completed', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[400], fontStyle: FontStyle.italic)),
                                          )
                                        else
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
                                    const SizedBox(height: 15),
                                    const Divider(color: Colors.white12),
                                    const SizedBox(height: 15),
                                    // Footer: Time and Location Stats
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildStatColumn('Check In', emp['check_in'] ?? '--:--'),
                                        _buildStatColumn('Check Out', emp['check_out'] ?? '--:--'),
                                        _buildStatColumn('Hours', emp['hours'] ?? '--:--:--'),
                                      ],
                                    ),
                                    const SizedBox(height: 15),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            emp['location'] ?? 'Unknown',
                                            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w600, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
