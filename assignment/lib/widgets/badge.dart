import 'package:flutter/material.dart';
import '../utils/app_utils.dart';

class AppBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool outlined;

  const AppBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.radius = 12,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = backgroundColor ?? AppColors.accent;
    final Color fg = foregroundColor ?? AppColors.textPrimary;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : bg,
        borderRadius: BorderRadius.circular(radius),
        border: outlined ? Border.all(color: bg) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: outlined ? bg : fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}


