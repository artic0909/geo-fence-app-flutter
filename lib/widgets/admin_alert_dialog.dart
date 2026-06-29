import 'package:flutter/material.dart';

class AdminAlertDialog extends StatelessWidget {
  final String title;
  final String message;
  final bool isSuccess;

  const AdminAlertDialog({
    super.key,
    required this.title,
    required this.message,
    this.isSuccess = true,
  });

  static Future<void> show(BuildContext context, {required String title, required String message, bool isSuccess = true}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => AdminAlertDialog(
        title: title,
        message: message,
        isSuccess: isSuccess,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color cardDark = Color(0xFF1E1E1E);
    const Color goldMain = Color(0xFFD4AF37);
    final Color iconColor = isSuccess ? Colors.greenAccent : Colors.redAccent;
    final IconData icon = isSuccess ? Icons.check_circle_outline : Icons.error_outline;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: goldMain.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 60,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: goldMain,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: goldMain,
                  foregroundColor: const Color(0xFF121212),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'OKAY',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
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
