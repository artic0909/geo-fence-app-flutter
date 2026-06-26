import 'package:flutter/material.dart';
import 'dart:ui';

enum AlertType { error, warning, info, success }

class CustomAlertDialog extends StatefulWidget {
  final String title;
  final String message;
  final AlertType type;
  final VoidCallback? onDismiss;

  const CustomAlertDialog({
    super.key,
    required this.title,
    required this.message,
    this.type = AlertType.error,
    this.onDismiss,
  });

  static void show(BuildContext context, {required String title, required String message, AlertType type = AlertType.error, VoidCallback? onDismiss}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Alert',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return CustomAlertDialog(title: title, message: message, type: type, onDismiss: onDismiss);
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<CustomAlertDialog> createState() => _CustomAlertDialogState();
}

class _CustomAlertDialogState extends State<CustomAlertDialog> with SingleTickerProviderStateMixin {
  late AnimationController _iconController;
  late Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _iconController.forward();
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  Color _getPrimaryColor() {
    switch (widget.type) {
      case AlertType.error: return Colors.red.shade600;
      case AlertType.warning: return Colors.orange.shade600;
      case AlertType.success: return Colors.green.shade600;
      case AlertType.info: return Colors.blue.shade600;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case AlertType.error: return Icons.error_outline_rounded;
      case AlertType.warning: return Icons.warning_amber_rounded;
      case AlertType.success: return Icons.check_circle_outline_rounded;
      case AlertType.info: return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = _getPrimaryColor();

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: primaryColor.withValues(alpha: 0.2), blurRadius: 30, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _iconScale,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getIcon(), color: primaryColor, size: 48),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A), letterSpacing: -0.5),
              ),
              const SizedBox(height: 12),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black.withValues(alpha: 0.6), height: 1.5),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (widget.onDismiss != null) widget.onDismiss!();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('OKAY', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
