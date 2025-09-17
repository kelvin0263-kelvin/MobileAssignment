import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/job_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_utils.dart';
import '../models/job.dart';
import 'job_details_screen.dart';
import '../widgets/app_header.dart';
import '../widgets/job_card.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<JobProvider>(context, listen: false).loadJobs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(subtitle: 'Task'),
            Expanded(
              child: Consumer<JobProvider>(
                builder: (context, jobProvider, child) {
                  if (jobProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (jobProvider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error loading jobs',
                            style: AppTextStyles.headline2,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            jobProvider.error!,
                            style: AppTextStyles.body2,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => jobProvider.loadJobs(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (jobProvider.jobs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.assignment_outlined,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No jobs assigned',
                            style: AppTextStyles.headline2,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'You don\'t have any jobs assigned yet.',
                            style: AppTextStyles.body2,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => jobProvider.loadJobs(),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: jobProvider.jobs.length,
                      itemBuilder: (context, index) {
                        final job = jobProvider.jobs[index];
                        return JobCard(
                          job: job,
                          onTap: () {
                            Provider.of<JobProvider>(context, listen: false).selectJob(job);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => JobDetailsScreen(jobId: job.id),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

}
