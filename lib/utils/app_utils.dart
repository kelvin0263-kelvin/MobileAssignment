import 'package:flutter/material.dart';
import '../models/job.dart';

class AppColors {
  // Modern green color palette for workshop theme
  static const Color primary = Color(0xFF2E7D32); // Professional dark green
  static const Color primaryLight = Color(0xFF4CAF50); // Light green
  static const Color primaryDark = Color(0xFF1B5E20); // Darker green
  static const Color accent = Color(0xFF66BB6A); // Soft accent green
  static const Color secondary = Color(0xFF37474F); // Blue-gray for contrast
  
  // Background colors
  static const Color background = Color(0xFFF8F9FA); // Light gray background
  static const Color surface = Colors.white;
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFC107); // Yellow for in-progress
  static const Color info = Color(0xFF1976D2);
  static const Color onHold = Color(0xFFFF5722);
  
  // Text colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Colors.white;
  
  // UI elements
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x1A000000);
  static const Color overlay = Color(0x80000000);
  
  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class AppTextStyles {
  static const TextStyle headline1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle headline2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle headline3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );
  
  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
}

class JobStatusHelper {
  static String getStatusText(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
        return 'Pending';
      case JobStatus.accepted:
        return 'Accepted';
      case JobStatus.inProgress:
        return 'In Progress';
      case JobStatus.onHold:
        return 'On Hold';
      case JobStatus.completed:
        return 'Completed';
    }
  }

  static Color getStatusColor(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
        return AppColors.warning;
      case JobStatus.accepted:
        return AppColors.info;
      case JobStatus.inProgress:
        return AppColors.warning; // Yellow for in-progress
      case JobStatus.onHold:
        return AppColors.error;
      case JobStatus.completed:
        return AppColors.success;
    }
  }

  static IconData getStatusIcon(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
        return Icons.schedule;
      case JobStatus.accepted:
        return Icons.check_circle_outline;
      case JobStatus.inProgress:
        return Icons.play_circle_outline;
      case JobStatus.onHold:
        return Icons.pause_circle_outline;
      case JobStatus.completed:
        return Icons.check_circle;
    }
  }
}

class DateHelper {
  static String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  static String formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class ValidationHelper {
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    return RegExp(r'^\+?[\d\s-]+$').hasMatch(phone);
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }
}
