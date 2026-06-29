import 'package:flutter/material.dart';
import 'dart:math' as math;

class AdminLoader extends StatefulWidget {
  final String message;
  
  const AdminLoader({super.key, this.message = "Securely loading your workspace..."});

  @override
  State<AdminLoader> createState() => _AdminLoaderState();
}

class _AdminLoaderState extends State<AdminLoader> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF121212);
    const Color goldMain = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: bgDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: goldMain.withValues(alpha: 0.15), blurRadius: 30, spreadRadius: 10),
                ],
                border: Border.all(color: goldMain.withValues(alpha: 0.3), width: 1),
              ),
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 1.0 + (0.2 * math.sin(_pulseController.value * math.pi));
                  return Transform.scale(
                    scale: scale,
                    child: const Icon(Icons.location_on, color: goldMain, size: 40),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
            const Text("INITIALIZING", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: goldMain, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text(widget.message, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}
