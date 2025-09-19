import 'package:flutter/material.dart';
import '../models/job.dart';
import '../utils/app_utils.dart';
import 'badge.dart';

class DashboardJobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;

  const DashboardJobCard({super.key, required this.job, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Align visuals with redesigned JobCard
    const Color red700 = Color(0xFFB91C1C);
    const Color red500 = Color(0xFFEF4444);
    const Color amber700 = Color(0xFFB45309);
    const Color yellow400 = Color(0xFFFACC15);
    const Color blue700 = Color(0xFF1D4ED8);
    const Color blue500 = Color(0xFF3B82F6);
    const Color orange700 = Color(0xFFC2410C);
    const Color orange500 = Color(0xFFF97316);
    const Color green700 = Color(0xFF15803D);
    const Color green500 = Color(0xFF22C55E);
    const Color gray700 = Color(0xFF374151);
    const Color gray500 = Color(0xFF6B7280);
    const Color buttonBlue600 = Color(0xFF2563EB);
    const Color buttonBlue700 = Color(0xFF1D4ED8);

    (Color, Color) statusColors;
    switch (job.status) {
      case JobStatus.pending:
        statusColors = (blue700, blue500.withOpacity(0.20));
        break;
      case JobStatus.inProgress:
        statusColors = (orange700, orange500.withOpacity(0.20));
        break;
      case JobStatus.completed:
        statusColors = (green700, green500.withOpacity(0.20));
        break;
      case JobStatus.accepted:
        statusColors = (blue700, blue500.withOpacity(0.20));
        break;
      case JobStatus.onHold:
        statusColors = (orange700, orange500.withOpacity(0.20));
        break;
      case JobStatus.declined:
        statusColors = (gray700, gray500.withOpacity(0.20));
        break;
    }
    final String statusLabel = _statusLabel(job.status);

    (Color, Color) priorityColors;
    final String priorityLabel = _priorityLabel(job);
    switch (priorityLabel) {
      case 'high':
      case 'urgent':
        priorityColors = (red700, red500.withOpacity(0.20));
        break;
      case 'medium':
        priorityColors = (amber700, yellow400.withOpacity(0.25));
        break;
      case 'low':
        priorityColors = (AppColors.textSecondary, gray500.withOpacity(0.30));
        break;
      default:
        priorityColors = (AppColors.textSecondary, gray500.withOpacity(0.30));
    }

    final String subtitle = _subtitle(job);
    final String timeLabel = _estimatedDurationLabel(job);

    return Card(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tags
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _tag(_capitalize(priorityLabel), priorityColors.$1, priorityColors.$2),
                    _tag(_capitalize(statusLabel), statusColors.$1, statusColors.$2),
                  ],
                ),
              ),
              // Title
              Text(
                job.jobName,
                style: AppTextStyles.headline3,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Subtitle
              Text(
                subtitle,
                style: AppTextStyles.body2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Bottom row: time + button
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      timeLabel,
                      style: AppTextStyles.body2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    label: Text(
                      'View Job',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonBlue600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.pressed)) {
                          return buttonBlue700.withOpacity(0.12);
                        }
                        return null;
                      }),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String text, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500, color: fg),
      ),
    );
  }

  String _priorityLabel(Job job) {
    final p = job.priority?.trim().toLowerCase();
    if (p == 'urgent') return 'urgent';
    if (p == 'high') return 'high';
    if (p == 'low') return 'low';
    if (p == 'medium') return 'medium';
    switch (job.status) {
      case JobStatus.onHold:
        return 'high';
      case JobStatus.inProgress:
        return 'medium';
      case JobStatus.completed:
        return 'low';
      default:
        return 'medium';
    }
  }

  String _statusLabel(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
        return 'pending';
      case JobStatus.accepted:
        return 'accepted';
      case JobStatus.inProgress:
        return 'in-progress';
      case JobStatus.onHold:
        return 'on-hold';
      case JobStatus.completed:
        return 'completed';
      case JobStatus.declined:
        return 'declined';
    }
  }

  String _subtitle(Job job) {
    final vehicleTitle = [job.vehicle?.brand, job.vehicle?.model]
        .where((e) => (e ?? '').toString().isNotEmpty)
        .join(' ')
        .trim();
    if (vehicleTitle.isEmpty) return job.customer.name;
    return '$vehicleTitle • ${job.customer.name}';
  }

  String _estimatedDurationLabel(Job job) {
    final int? minutes = job.estimatedDuration ?? job.actualDuration;
    if (minutes == null) return '—';
    if (minutes >= 60) {
      final int hours = minutes ~/ 60;
      final int mins = minutes % 60;
      if (mins == 0) return '${hours}h est.';
      return '${hours}h ${mins}m est.';
    }
    return '${minutes}m est.';
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    if (text.length == 1) return text.toUpperCase();
    return text[0].toUpperCase() + text.substring(1);
  }
}

