import 'package:flutter/material.dart';
import '../utils/app_utils.dart';
import '../models/job.dart';

class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback? onTap;

  const JobCard({super.key, required this.job, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.jobName,
                          style: AppTextStyles.headline2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Job ID: ${job.id}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: JobStatusHelper.getStatusColor(job.status),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      JobStatusHelper.getStatusText(job.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                job.description,
                style: AppTextStyles.body2,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.person,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      job.customer.name,
                      style: AppTextStyles.caption,
                    ),
                  ),
                  const Icon(
                    Icons.directions_car,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    job.vehicle?.plateNo ?? '-',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateHelper.formatDate(job.createdAt),
                    style: AppTextStyles.caption,
                  ),
                  const Spacer(),
                  if (job.assignedParts.isNotEmpty)
                    Text(
                      '${job.assignedParts.length} parts',
                      style: AppTextStyles.caption,
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


