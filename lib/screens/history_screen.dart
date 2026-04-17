import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/attendance.dart';
import 'dart:convert';
import 'dart:ui';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with TickerProviderStateMixin {
  List<Attendance> _allAttendances = [];
  List<Attendance> _filteredAttendances = [];
  bool _isLoading = true;
  String? _errorMessage;

  int _visibleCount = 5;
  DateTime? _startDate;
  DateTime? _endDate;

  late AnimationController _radarController;
  late AnimationController _listController;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _radarController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _listController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
  }

  @override
  void dispose() {
    _radarController.dispose();
    _listController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final response = await ApiService.getAttendanceHistory();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> attendanceList = [];
        if (data['attendances'] is List) {
          attendanceList = data['attendances'];
        } else if (data is List) {
          attendanceList = data;
        } else if (data['data'] is List) {
          attendanceList = data['data'];
        }

        final List<Attendance> parsedAttendances = [];
        for (var item in attendanceList) {
          try { parsedAttendances.add(Attendance.fromJson(item)); } catch (e) {}
        }

        setState(() {
          _allAttendances = parsedAttendances;
          _isLoading = false;
          _errorMessage = null;
          _applyFilters();
          _listController.forward(from: 0);
        });
      } else {
        setState(() { _isLoading = false; _errorMessage = 'Failed to load history'; });
      }
    } catch (e) {
      setState(() { _isLoading = false; _errorMessage = 'Connection Error'; });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredAttendances = _allAttendances.where((attendance) {
        try {
          String ds = attendance.date;
          if (ds.length >= 10) ds = ds.substring(0, 10);
          final date = DateTime.parse(ds);
          final start = _startDate != null ? DateTime(_startDate!.year, _startDate!.month, _startDate!.day) : null;
          final end = _endDate != null ? DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59) : null;
          if (start != null && date.isBefore(start)) return false;
          if (end != null && date.isAfter(end)) return false;
          return true;
        } catch (e) { return true; }
      }).toList();
      _visibleCount = 5;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color saffron = Color(0xFFFF9933);
    const Color green = Color(0xFF138808);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: FlagBannerPainter(saffron: saffron, green: green))),
          Positioned.fill(child: Opacity(opacity: 0.1, child: Image.asset('assets/map.png', fit: BoxFit.cover))),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _radarController,
              builder: (context, child) => CustomPaint(
                painter: RadarSweepPainter(angle: _radarController.value * 2 * 3.1415, color: saffron.withOpacity(0.04)),
              ),
            ),
          ),

          Column(
            children: [
              _buildHeader(saffron),
              if (_startDate != null) _buildFilterTag(saffron),
              Expanded(
                child: _isLoading 
                    ? _buildLoading()
                    : _filteredAttendances.isEmpty 
                    ? _buildEmpty()
                    : _buildList(saffron, green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color saffron) {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
              child: const Icon(Icons.arrow_back_rounded, size: 20),
            ),
          ),
          const Text("MY ATTENDANCE", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
          GestureDetector(
            onTap: _selectDateRange,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: saffron, shape: BoxShape.circle, boxShadow: [BoxShadow(color: saffron.withOpacity(0.3), blurRadius: 10)]),
              child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTag(Color saffron) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: _clearFilters,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20)),
          child: Text(
            "${_startDate!.day} ${_getMonthName(_startDate!.month)} - ${_endDate!.day} ${_getMonthName(_endDate!.month)}  ✕",
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildList(Color saffron, Color green) {
    final displayItems = _filteredAttendances.take(_visibleCount).toList();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: displayItems.length + (_filteredAttendances.length > _visibleCount ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == displayItems.length) return _buildLoadMore(saffron);
        
        return AnimatedBuilder(
          animation: _listController,
          builder: (context, child) {
            final delay = (index * 0.1).clamp(0.0, 0.5);
            final anim = Interval(delay, (delay + 0.5).clamp(0.0, 1.0), curve: Curves.easeOutQuart).transform(_listController.value);
            return Opacity(
              opacity: anim,
              child: Transform.translate(offset: Offset(0, 30 * (1 - anim)), child: child),
            );
          },
          child: _buildNewCard(displayItems[index], saffron, green),
        );
      },
    );
  }

  Widget _buildNewCard(Attendance attend, Color saffron, Color green) {
    final status = attend.status.toLowerCase();
    final Color color = status == 'present' ? green : (status == 'late' ? saffron : Colors.red);
    
    DateTime? dt;
    try { 
      String ds = attend.date;
      if (ds.length >= 10) ds = ds.substring(0, 10);
      dt = DateTime.parse(ds); 
    } catch(e) {}
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 55,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dt != null ? dt.day.toString().padLeft(2, '0') : "??", 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)
                      ),
                      Text(
                        dt != null ? _getMonthName(dt.month) : "???", 
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color)
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDayName(attend.date).toUpperCase(), 
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 10, color: Colors.black.withOpacity(0.3)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              attend.locationName, 
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.black.withOpacity(0.3))
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    attend.status.toUpperCase(), 
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
            ),
            child: Row(
              children: [
                _buildTimeColumn("CHECK-IN", _formatTime(attend.checkIn), Icons.access_time_filled_rounded, Colors.blue),
                const Spacer(),
                Container(width: 1, height: 25, color: Colors.grey.withOpacity(0.1)),
                const Spacer(),
                _buildTimeColumn("CHECK-OUT", _formatTime(attend.checkOut), Icons.alarm_on_rounded, Colors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(String label, String time, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey.shade600, letterSpacing: 0.5)),
            Text(time, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadMore(Color saffron) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: GestureDetector(
          onTap: () => setState(() => _visibleCount += 5),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)]),
            child: const Text("MORE RECORDS", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(child: CircularProgressIndicator(color: const Color(0xFFFF9933)));
  }

  Widget _buildEmpty() {
    return const Center(child: Text("NO RECORDS FOUND", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey)));
  }

  String _getMonthName(int month) => ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"][month - 1];
  
  String _getDayName(String date) {
    try {
      String ds = date;
      if (ds.length >= 10) ds = ds.substring(0, 10);
      DateTime dt = DateTime.parse(ds);
      return ["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"][dt.weekday - 1];
    } catch (e) {
      return "???";
    }
  }
  
  String _formatTime(String? time) {
    if (time == null || time == "N/A" || time == "") return "--:--";
    try {
      final t = DateTime.parse(time).toLocal();
      final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
      return "${h.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')} ${t.hour >= 12 ? 'PM':'AM'}";
    } catch (e) { return "--:--"; }
  }

  Future<void> _selectDateRange() async {
    final res = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime.now());
    if (res != null) {
      setState(() { _startDate = res.start; _endDate = res.end; });
      _applyFilters();
      _listController.forward(from: 0);
    }
  }

  void _clearFilters() {
    setState(() { _startDate = null; _endDate = null; });
    _applyFilters();
    _listController.forward(from: 0);
  }
}

class RadarSweepPainter extends CustomPainter {
  final double angle;
  final Color color;
  RadarSweepPainter({required this.angle, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..shader = SweepGradient(center: Alignment.center, startAngle: angle, endAngle: angle + 0.5, colors: [color.withOpacity(0), color]).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.longestSide, paint);
  }
  @override
  bool shouldRepaint(RadarSweepPainter old) => old.angle != angle;
}

class FlagBannerPainter extends CustomPainter {
  final Color saffron, green;
  FlagBannerPainter({required this.saffron, required this.green});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    canvas.drawPath(Path()..moveTo(0, 0)..lineTo(size.width * 0.7, 0)..lineTo(0, size.height * 0.45)..close(), paint..color = saffron);
    canvas.drawPath(Path()..moveTo(size.width, size.height)..lineTo(size.width * 0.3, size.height)..lineTo(size.width, size.height * 0.55)..close(), paint..color = green);
  }
  @override
  bool shouldRepaint(CustomPainter old) => false;
}
