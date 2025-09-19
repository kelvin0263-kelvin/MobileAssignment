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
    final statusColor = JobStatusHelper.getStatusColor(job.status);
    final statusText = JobStatusHelper.getStatusText(job.status);
    final vehicleTitle = [job.vehicle?.brand, job.vehicle?.model, if (job.vehicle?.year != null) job.vehicle!.year.toString()]
        .where((e) => (e ?? '').toString().isNotEmpty)
        .join(' ')
        .trim();
    final tasks = job.tasks;
    final totalTasks = tasks.length;
    final doneTasks = tasks.where((t) => t.status == JobTaskStatus.completed || t.status == JobTaskStatus.skipped).length;
    final progress = totalTasks == 0 ? 0.0 : doneTasks / totalTasks;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: AppColors.cardGradient,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + chips
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      job.jobName,
                      style: AppTextStyles.headline2,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _chip(statusText, statusColor, filled: true),
                      _chip(_priorityLabel(job).toUpperCase(), _priorityColor(job)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Customer + vehicle
              _meta(Icons.person, job.customer.name),
              const SizedBox(height: 6),
              _meta(Icons.directions_car, vehicleTitle.isEmpty ? '-' : '$vehicleTitle  (${job.vehicle?.plateNo ?? '-'})'),
              if (job.description.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(job.description, style: AppTextStyles.body2, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 12),
              // Progress + stats
              if (totalTasks > 0) ...[
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: AppColors.divider,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('$doneTasks/$totalTasks', style: AppTextStyles.caption),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _pill(Icons.checklist, '${job.tasks.length} tasks'),
                  _pill(Icons.note_alt_outlined, '${job.notes.length} notes'),
                  _pill(Icons.build, '${job.assignedParts.length} parts'),
                  if (job.requestedServices.isNotEmpty) _pill(Icons.list_alt, '${job.requestedServices.length} services'),
                ],
              ),
              const SizedBox(height: 12),
              // Footer
              Row(
                children: [
                  const Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      DateHelper.formatDateTime(job.createdAt),
                      style: AppTextStyles.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    label: const Text('Details'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
    child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(text, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color, {bool filled = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? color.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(color: filled ? color : color),
      ),
    );
  }

  // Derive a simple priority from status for demo purposes
  String _priorityLabel(Job job) {
    if (job.status == JobStatus.onHold) return 'high';
    if (job.status == JobStatus.inProgress) return 'medium';
    if (job.status == JobStatus.completed) return 'low';
    return 'medium';
  }

  Color _priorityColor(Job job) {
    if (job.status == JobStatus.onHold) return AppColors.error.withOpacity(0.85);
    if (job.status == JobStatus.inProgress) return AppColors.warning;
    if (job.status == JobStatus.completed) return AppColors.success;
    return AppColors.info;
  }
}

