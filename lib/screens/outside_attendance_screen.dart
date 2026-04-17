import 'package:flutter/material.dart';

class OutsideAttendanceScreen extends StatelessWidget {
  const OutsideAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Outside Attendance'),
        backgroundColor: const Color(0xFFFF9933),
      ),
      body: const Center(
        child: Text(
          'Outside Attendance Screen\n(Workings and design to be implemented)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
