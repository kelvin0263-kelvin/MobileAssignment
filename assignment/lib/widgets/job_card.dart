import 'package:flutter/material.dart';
import '../utils/app_utils.dart';
import '../models/job.dart';

class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback? onTap;

  const JobCard({super.key, required this.job, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Tailwind-like palette and sizing conversions (from user's spec)
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

    final (Color, Color) priorityColors = _priorityTagColors(
      job,
      red700: red700,
      red500: red500,
      amber700: amber700,
      yellow400: yellow400,
      gray700: gray700,
      gray500: gray500,
    );
    final (Color, Color) statusColors = _statusTagColors(
      job.status,
      blue700: blue700,
      blue500: blue500,
      orange700: orange700,
      orange500: orange500,
      green700: green700,
      green500: green500,
      gray700: gray700,
      gray500: gray500,
    );

    final String priorityLabel = _priorityLabel(job);
    final String statusLabel = _statusLabel(job.status);
    final String subtitle = _subtitle(job);
    final String timeLabel = _estimatedDurationLabel(job);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0, // no shadow
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)), // gray border
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // space-y-4 group: we'll use explicit SizedBox(16)
              // Tags row (mb-1 -> 4px)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Wrap(
                  spacing: 8, // gap-2
                  runSpacing: 8,
                  children: [
                    _tag(_capitalize(priorityLabel), priorityColors.$1, priorityColors.$2),
                    _tag(_capitalize(statusLabel), statusColors.$1, statusColors.$2),
                  ],
                ),
              ),
              // Title (text-lg font-semibold, mb-2 -> 8px)
              Text(
                job.jobName,
                style: AppTextStyles.headline3, // 18, w600
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Subtitle (text-sm text-muted-foreground, mb-3 -> 12px)
              Text(
                subtitle,
                style: AppTextStyles.body2, // 14 regular, secondary color
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
                      style: AppTextStyles.body2, // 14
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
}


// Helpers for tags and labels (kept private to this file)
Widget _tag(String text, Color fg, Color bg) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // px-3 py-1.5
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999), // rounded-full
    ),
    child: Text(
      text,
      style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500, color: fg), // text-xs font-medium
    ),
  );
}

String _priorityLabel(Job job) {
  final p = job.priority?.trim().toLowerCase();
  if (p == 'urgent') return 'urgent';
  if (p == 'high') return 'high';
  if (p == 'low') return 'low';
  if (p == 'medium') return 'medium';
  // Fallbacks derived from status
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

(Color, Color) _priorityTagColors(
  Job job, {
  required Color red700,
  required Color red500,
  required Color amber700,
  required Color yellow400,
  required Color gray700,
  required Color gray500,
}) {
  final label = _priorityLabel(job);
  switch (label) {
    case 'urgent':
    case 'high':
      return (red700, red500.withOpacity(0.20)); // text-red-700 bg-red-500/20
    case 'medium':
      return (amber700, yellow400.withOpacity(0.25)); // text-amber-700 bg-yellow-400/25
    case 'low':
      return (AppColors.textSecondary, gray500.withOpacity(0.30)); // text-muted-foreground bg-muted/30
    default:
      return (AppColors.textSecondary, gray500.withOpacity(0.30));
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

(Color, Color) _statusTagColors(
  JobStatus status, {
  required Color blue700,
  required Color blue500,
  required Color orange700,
  required Color orange500,
  required Color green700,
  required Color green500,
  required Color gray700,
  required Color gray500,
}) {
  switch (status) {
    case JobStatus.pending:
      return (blue700, blue500.withOpacity(0.20)); // text-blue-700 bg-blue-500/20
    case JobStatus.inProgress:
      return (orange700, orange500.withOpacity(0.20)); // text-orange-700 bg-orange-500/20
    case JobStatus.completed:
      return (green700, green500.withOpacity(0.20)); // text-green-700 bg-green-500/20
    case JobStatus.accepted:
      return (blue700, blue500.withOpacity(0.20)); // treat like pending
    case JobStatus.onHold:
      return (orange700, orange500.withOpacity(0.20));
    case JobStatus.declined:
      return (gray700, gray500.withOpacity(0.20)); // fallback
  }
}

String _subtitle(Job job) {
  final vehicleTitle = [job.vehicle?.brand, job.vehicle?.model]
      .where((e) => (e ?? '').toString().isNotEmpty)
      .join(' ')
      .trim();
  final String vehiclePart = vehicleTitle.isEmpty ? '' : vehicleTitle;
  if (vehiclePart.isEmpty) {
    return job.customer.name;
  }
  return '$vehiclePart • ${job.customer.name}';
}

String _estimatedDurationLabel(Job job) {
  final int? minutes = job.estimatedDuration ?? job.actualDuration;
  if (minutes == null) {
    return '—';
  }
  if (minutes >= 60) {
    final int hours = minutes ~/ 60;
    final int mins = minutes % 60;
    if (mins == 0) {
      return '${hours}h est.';
    }
    return '${hours}h ${mins}m est.';
  }
  return '${minutes}m est.';
}

String _capitalize(String text) {
  if (text.isEmpty) return text;
  if (text.length == 1) return text.toUpperCase();
  return text[0].toUpperCase() + text.substring(1);
}


