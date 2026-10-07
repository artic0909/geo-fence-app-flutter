import 'dart:convert';
import 'package:flutter/material.dart';
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
  List<dynamic> _filteredEmployees = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPresentEmployees();
  }

  Future<void> _fetchPresentEmployees() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getTodayPresent();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _employees = data['present_employees'] ?? [];
          _filteredEmployees = _employees;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching present employees: $e");
      setState(() => _isLoading = false);
    }
  }

  void _filterEmployees(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredEmployees = _employees;
      } else {
        _filteredEmployees = _employees.where((emp) {
          final name = (emp['name'] ?? '').toString().toLowerCase();
          final id = (emp['employee_id'] ?? '').toString().toLowerCase();
          final loc = (emp['location'] ?? '').toString().toLowerCase();
          final q = query.toLowerCase();
          return name.contains(q) || id.contains(q) || loc.contains(q);
        }).toList();
      }
    });
  }

  void _showAppUsageDialog(BuildContext context, String employeeName, dynamic usages) {
    if (usages == null) return;
    
    List<dynamic> summaryList = [];
    String? totalDuration;

    if (usages is Map) {
      if (usages['summary'] is List) {
        summaryList = usages['summary'];
      }
      totalDuration = usages['total_tracked_formatted']?.toString();
    } else if (usages is List) {
      summaryList = usages;
    }

    if (summaryList.isEmpty) return;

    const Color bgDark = Color(0xFF121212);
    const Color cardDark = Color(0xFF1E1E1E);
    const Color goldLight = Color(0xFFF3E5AB);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.phone_android_rounded, color: Colors.blueAccent, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'App Usage Track Record',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              employeeName,
                              style: const TextStyle(color: goldLight, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      if (totalDuration != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            'Total: $totalDuration',
                            style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 8),
                  Text(
                    'Apps used during work session (${summaryList.length}):',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: summaryList.length,
                      itemBuilder: (context, idx) {
                        final item = summaryList[idx];
                        final appName = item['app_name'] ?? item['package_name'] ?? 'Unknown App';
                        final packageName = item['package_name'] ?? '';
                        final beforeFmt = item['before_lunch_formatted']?.toString();
                        final afterFmt = item['after_lunch_formatted']?.toString();
                        final totalFmt = item['total_formatted'] ?? item['usage_formatted'] ?? '${item['total_seconds'] ?? item['usage_seconds'] ?? 0}s';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: bgDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[850]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.apps_rounded, color: Colors.blueAccent, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          appName,
                                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                        ),
                                        if (packageName.isNotEmpty)
                                          Text(
                                            packageName,
                                            style: TextStyle(color: Colors.grey[600], fontSize: 10, fontFamily: 'monospace'),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      totalFmt,
                                      style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              if (beforeFmt != null || afterFmt != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (beforeFmt != null && beforeFmt != '0s')
                                      Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Pre-Lunch: $beforeFmt',
                                          style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    if (afterFmt != null && afterFmt != '0s')
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.cyanAccent.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Post-Lunch: $afterFmt',
                                          style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF121212);
    const Color cardDark = Color(0xFF1E1E1E);
    const Color goldMain = Color(0xFFD4AF37);
    const Color goldLight = Color(0xFFF3E5AB);

    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        backgroundColor: bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Today's Present",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: goldMain))
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardDark,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey[850]!),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterEmployees,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search by name, ID, location...',
                        hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: goldMain),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterEmployees('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      ),
                    ),
                  ),
                ),

                // Employee List
                Expanded(
                  child: _filteredEmployees.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off_outlined, size: 60, color: Colors.grey[700]),
                              const SizedBox(height: 10),
                              Text("No employees found", style: TextStyle(color: Colors.grey[500], fontSize: 16, letterSpacing: 1)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          itemCount: _filteredEmployees.length,
                          itemBuilder: (context, index) {
                            final emp = _filteredEmployees[index];
                            final bool isOutside = (emp['type'] ?? '') == 'Outside';
                            final bool isCheckedOut = emp['check_out'] != null;
                            final dynamic usages = emp['app_usages'];
                            final bool hasAppUsages = usages != null && (usages is List) && usages.isNotEmpty;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: cardDark,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.grey[850]!,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
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
                                                  if (hasAppUsages)
                                                    InkWell(
                                                      onTap: () => _showAppUsageDialog(context, emp['name'] ?? 'Employee', usages),
                                                      borderRadius: BorderRadius.circular(20),
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: Colors.blueAccent.withValues(alpha: 0.15),
                                                          border: Border.all(color: Colors.blueAccent),
                                                          borderRadius: BorderRadius.circular(20),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            const Icon(Icons.phone_android_rounded, size: 12, color: Colors.blueAccent),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              'App Usage (${usages.length})',
                                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                                                            ),
                                                          ],
                                                        ),
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
