import 'dart:async';
import 'package:flutter/material.dart';

class KioskCountdownDialog extends StatefulWidget {
  final VoidCallback onTimerComplete;

  const KioskCountdownDialog({super.key, required this.onTimerComplete});

  static Future<void> show(BuildContext context, {required VoidCallback onComplete}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => KioskCountdownDialog(onTimerComplete: onComplete),
    );
  }

  @override
  State<KioskCountdownDialog> createState() => _KioskCountdownDialogState();
}

class _KioskCountdownDialogState extends State<KioskCountdownDialog> with SingleTickerProviderStateMixin {
  int _seconds = 3;
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_seconds > 1) {
          _seconds--;
        } else {
          timer.cancel();
          _pulseController.stop();
          Navigator.of(context).pop();
          widget.onTimerComplete();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_person, size: 60, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              "PHONE RESTRICTION ACTIVE",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Your phone will be locked to this app while you are checked in.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 40),
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.redAccent, blurRadius: 20, spreadRadius: 5),
                  ],
                ),
                child: Center(
                  child: Text(
                    "$_seconds",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              "Locking device...",
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
