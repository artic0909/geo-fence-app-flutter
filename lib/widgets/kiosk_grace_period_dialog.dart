import 'dart:async';
import 'package:flutter/material.dart';

class KioskGracePeriodDialog extends StatefulWidget {
  final DateTime requestedTime;
  final int maxSeconds;

  const KioskGracePeriodDialog({
    super.key,
    required this.requestedTime,
    this.maxSeconds = 120,
  });

  static bool _isShowing = false;
  
  static Future<void> show(BuildContext context, DateTime requestedTime) async {
    if (_isShowing) return;
    _isShowing = true;
    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black87,
        useRootNavigator: true,
        builder: (context) => KioskGracePeriodDialog(requestedTime: requestedTime),
      );
    } finally {
      _isShowing = false;
    }
  }
  
  static void hide(BuildContext context) {
    if (_isShowing) {
      Navigator.of(context, rootNavigator: true).pop();
      _isShowing = false;
    }
  }

  @override
  State<KioskGracePeriodDialog> createState() => _KioskGracePeriodDialogState();
}

class _KioskGracePeriodDialogState extends State<KioskGracePeriodDialog> {
  Timer? _timer;
  int _secondsLeft = 120;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _updateTime();
    });
  }
  
  void _updateTime() {
    final diff = DateTime.now().difference(widget.requestedTime).inSeconds;
    final remaining = widget.maxSeconds - diff;
    if (remaining <= 0) {
      setState(() => _secondsLeft = 0);
    } else {
      setState(() => _secondsLeft = remaining);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
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
            const Icon(Icons.timer, size: 60, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              "ACCEPT PINNING",
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
              "Please accept the screen pinning permission to stay checked in.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.orangeAccent, blurRadius: 20, spreadRadius: 5),
                ],
              ),
              child: Center(
                child: Text(
                  "$_secondsLeft\ns",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
