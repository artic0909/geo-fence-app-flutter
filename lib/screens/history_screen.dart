import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/attendance.dart';
import 'dart:convert';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Attendance> _attendances = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final response = await ApiService.getAttendanceHistory();
      print('History Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Debug: Print first attendance record to see the structure
        if (data['attendances'] is List &&
            (data['attendances'] as List).isNotEmpty) {
          print('First attendance record: ${data['attendances'][0]}');
          print('Check-in time: ${data['attendances'][0]['check_in']}');
          print('Check-out time: ${data['attendances'][0]['check_out']}');
          print('Date: ${data['attendances'][0]['date']}');
        }

        List<dynamic> attendanceList = [];

        if (data['attendances'] is List) {
          attendanceList = data['attendances'];
        } else if (data is List) {
          attendanceList = data;
        } else if (data['data'] is List) {
          attendanceList = data['data'];
        }

        print('Found ${attendanceList.length} attendance records');

        // Parse each attendance record with error handling
        final List<Attendance> parsedAttendances = [];

        for (var item in attendanceList) {
          try {
            final attendance = Attendance.fromJson(item);
            parsedAttendances.add(attendance);

            // Debug: Print converted times
            print(
              'Original Check-in: ${item['check_in']} -> Local: ${_formatDateTime(item['check_in'])}',
            );
            print(
              'Original Check-out: ${item['check_out']} -> Local: ${_formatDateTime(item['check_out'])}',
            );
          } catch (e) {
            print('Error parsing attendance item: $e');
            print('Problematic item: $item');
          }
        }

        setState(() {
          _attendances = parsedAttendances;
          _isLoading = false;
          _isRefreshing = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
          _errorMessage = 'Failed to load history: ${response.statusCode}';
        });
      }
    } catch (e) {
      print('Error loading history: $e');
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
        _errorMessage = 'Error loading history: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading history: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await _loadHistory();
  }

  String _formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date).toLocal();
      return '${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}';
    } catch (e) {
      return date;
    }
  }

  String _formatTime(String? time) {
    if (time == null) return 'N/A';
    try {
      // Parse as UTC and convert to local time
      final parsedTime = DateTime.parse(time).toLocal();
      return _formatTo12Hour(parsedTime);
    } catch (e) {
      // Fallback: try to extract time from string and convert to 12-hour
      if (time.contains(' ')) {
        final parts = time.split(' ');
        if (parts.length > 1) {
          final timePart = parts[1];
          if (timePart.contains(':')) {
            final timeComponents = timePart.split(':');
            if (timeComponents.length >= 2) {
              final hour = int.tryParse(timeComponents[0]) ?? 0;
              final minute = timeComponents[1];
              return _convertTo12Hour(hour, minute);
            }
          }
        }
      }
      return time;
    }
  }

  String _formatDateTime(String? datetime) {
    if (datetime == null) return 'N/A';
    try {
      final parsedDateTime = DateTime.parse(datetime).toLocal();
      final date =
          '${parsedDateTime.day.toString().padLeft(2, '0')}/${parsedDateTime.month.toString().padLeft(2, '0')}/${parsedDateTime.year}';
      final time = _formatTo12Hour(parsedDateTime);
      return '$date $time';
    } catch (e) {
      return datetime;
    }
  }

  String _formatTo12Hour(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    return _convertTo12Hour(hour, minute.toString().padLeft(2, '0'));
  }

  String _convertTo12Hour(int hour, String minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final twelveHour = hour % 12;
    final displayHour = twelveHour == 0 ? 12 : twelveHour;
    return '${displayHour.toString().padLeft(2, '0')}:$minute $period';
  }

  // FIXED: Correct day name calculation
  String _getDayName(String date) {
    try {
      final days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final parsedDate = DateTime.parse(date);
      // DateTime.weekday returns 1 for Monday, 7 for Sunday
      return days[parsedDate.weekday - 1];
    } catch (e) {
      return '';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Attendance Records',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your attendance history will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Failed to Load History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              _errorMessage ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(Attendance attendance, int index) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.fromLTRB(16, index == 0 ? 16 : 8, 16, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: _getStatusColor(attendance.status),
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.blue[700],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(attendance.date),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        attendance.status,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(
                          attendance.status,
                        ).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      attendance.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(attendance.status),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Check-in/Check-out Times with Full DateTime
              Column(
                children: [
                  if (attendance.checkIn != null)
                    _buildTimeDetailCard(
                      'Check In',
                      _formatDateTime(attendance.checkIn),
                      Icons.login,
                      Colors.green,
                    ),

                  if (attendance.checkIn != null && attendance.checkOut != null)
                    const SizedBox(height: 8),

                  if (attendance.checkOut != null)
                    _buildTimeDetailCard(
                      'Check Out',
                      _formatDateTime(attendance.checkOut),
                      Icons.logout,
                      Colors.orange,
                    ),
                ],
              ),

              // Duration (if both check-in and check-out exist)
              if (attendance.checkIn != null &&
                  attendance.checkOut != null &&
                  attendance.checkIn != 'N/A' &&
                  attendance.checkOut != 'N/A') ...[
                const SizedBox(height: 12),
                _buildDurationInfo(attendance.checkIn!, attendance.checkOut!),
              ],

              // Debug info (optional - you can remove this later)
              const SizedBox(height: 8),
              Text(
                'DB Times - In: ${attendance.checkIn ?? "N/A"}, Out: ${attendance.checkOut ?? "N/A"}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeDetailCard(
    String title,
    String datetime,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                datetime,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeCard(String title, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationInfo(String checkIn, String checkOut) {
    try {
      // Parse both times as UTC and convert to local for accurate calculation
      final checkInTime = DateTime.parse(checkIn).toLocal();
      final checkOutTime = DateTime.parse(checkOut).toLocal();
      final duration = checkOutTime.difference(checkInTime);

      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);

      String durationText;
      if (hours > 0) {
        durationText = '${hours}h ${minutes}m';
      } else {
        durationText = '${minutes}m';
      }

      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.purple[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, size: 14, color: Colors.purple[700]),
            const SizedBox(width: 6),
            Text(
              'Total: $durationText',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.purple[700],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return const SizedBox();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Attendance History',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue[700],
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.blue[700]),
            onPressed: _isRefreshing ? null : _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Loading your attendance history...',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              )
              : _errorMessage != null
              ? _buildErrorState()
              : _attendances.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                onRefresh: _refreshData,
                color: Colors.blue,
                backgroundColor: Colors.white,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _attendances.length,
                  itemBuilder: (context, index) {
                    return _buildAttendanceCard(_attendances[index], index);
                  },
                ),
              ),
    );
  }
}
