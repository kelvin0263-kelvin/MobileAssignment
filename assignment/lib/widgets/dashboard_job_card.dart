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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.jobName, style: AppTextStyles.headline2),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                job.customer.name,
                                style: AppTextStyles.caption,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppBadge(
                        label: _priorityLabel(job),
                        backgroundColor: _priorityColor(job),
                        foregroundColor: Colors.white,
                      ),
                      const SizedBox(height: 4),
                      AppBadge(
                        label: JobStatusHelper.getStatusText(job.status),
                        outlined: true,
                        backgroundColor: JobStatusHelper.getStatusColor(job.status),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.directions_car, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      job.customer.equipment,
                      style: AppTextStyles.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('(${job.customer.plateNo})', style: AppTextStyles.caption),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(DateHelper.formatDateTime(job.createdAt), style: AppTextStyles.caption),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(120, 40)),
                    child: const Text('View Details'),
                  ),
                ],
              )
            ],
          ),
        ),
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


