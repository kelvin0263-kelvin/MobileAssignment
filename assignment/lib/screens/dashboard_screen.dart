import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/job_provider.dart';
import '../utils/app_utils.dart';
import '../models/job.dart';
import 'task_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import '../widgets/app_bottom_nav.dart';
import 'job_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  String _viewMode = 'Day'; // 'Day' or 'Week'

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
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          const TaskScreen(),
          const SearchScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }

  Widget _buildHomeTab() {
    return SafeArea(
      child: Consumer<JobProvider>(
        builder: (context, jobProvider, child) {
          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.transparent,
                              child: Icon(
                                Icons.person,
                                color: AppColors.primary,
                                size: 30,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Consumer<AuthProvider>(
                                  builder: (context, authProvider, child) {
                                    return Text(
                                      authProvider.currentUser?.name ?? 'Mechanic Name',
                                      style: AppTextStyles.headline2.copyWith(
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                ),
                                Text(
                                  'Welcome back!',
                                  style: AppTextStyles.body2.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Day/Week Toggle
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildToggleButton('Day', _viewMode == 'Day'),
                            const SizedBox(width: 8),
                            _buildToggleButton('Week', _viewMode == 'Week'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Status Tabs
                      const TabBar(
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        indicatorColor: Colors.white,
                        tabs: [
                          Tab(icon: Icon(Icons.pause_circle_outline), text: 'On Hold'),
                          Tab(icon: Icon(Icons.play_circle_outline), text: 'In Progress'),
                          Tab(icon: Icon(Icons.check_circle_outline), text: 'Completed'),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tab contents
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (jobProvider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (jobProvider.error != null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Error loading jobs', style: AppTextStyles.headline2),
                              const SizedBox(height: 8),
                              Text(jobProvider.error!, style: AppTextStyles.body2, textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: () => jobProvider.loadJobs(), child: const Text('Retry')),
                            ],
                          ),
                        );
                      }

                      final filtered = _filterJobsByView(jobProvider.jobs);
                      final onHold = _byStatus(filtered, JobStatus.onHold);
                      final inProgress = _byStatus(filtered, JobStatus.inProgress);
                      final completed = _byStatus(filtered, JobStatus.completed);

                      return TabBarView(
                        children: [
                          _buildJobsList(onHold, empty: _emptyText('On Hold')),
                          _buildJobsList(inProgress, empty: _emptyText('In Progress')),
                          _buildJobsList(completed, empty: _emptyText('Completed')),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _emptyText(String status) => _viewMode == 'Day' ? 'No $status jobs today' : 'No $status jobs this week';

  // Helpers to filter by view
  List<Job> _filterJobsByView(List<Job> jobs) {
    if (_viewMode == 'Day') {
      return jobs.where((j) => _isSameDay(j.createdAt, DateTime.now())).toList();
    }
    // Week: Monday..Sunday of current week
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final endOfWeekExclusive = startOfWeek.add(const Duration(days: 7));
    return jobs.where((j) => (j.createdAt.isAtSameMomentAs(startOfWeek) || j.createdAt.isAfter(startOfWeek)) && j.createdAt.isBefore(endOfWeekExclusive)).toList();
  }

  List<Job> _byStatus(List<Job> jobs, JobStatus status) => jobs.where((j) => j.status == status).toList();

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildToggleButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _viewMode = text;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildJobsList(List<Job> jobs, {required String empty}) {
    if (jobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(empty, style: AppTextStyles.body2, textAlign: TextAlign.center),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            Provider.of<JobProvider>(context, listen: false).selectJob(job);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => JobDetailsScreen(jobId: job.id),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.jobName, style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Job ID: ${job.id}', style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: JobStatusHelper.getStatusColor(job.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    JobStatusHelper.getStatusText(job.status),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
