import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../providers/job_provider.dart';
import '../utils/app_utils.dart';
import '../models/job.dart';
import 'task_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import '../widgets/app_bottom_nav.dart';
import 'job_details_screen.dart';
import '../widgets/dashboard_job_card.dart';
import 'procedure_screen.dart';
import 'create_job_screen.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../services/offline_queue_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  String _selectedFilter = 'all'; // Track selected filter card

  // Dashboard filters
  // final TextEditingController _searchController = TextEditingController();
  // String _statusFilter = 'all';
  // String _priorityFilter = 'all';
  // String _sortBy = 'latest'; // latest | oldest


  // Dashboard filters
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<bool>? _connSub;
  StreamSubscription<bool>? _syncSub;
  Future<void> _refreshAfterSync() async {
    // Allow backend a brief moment to reflect recent writes
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    Provider.of<JobProvider>(context, listen: false).loadJobs();
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<JobProvider>(context, listen: false).loadJobs();
      // Ensure Total filter is selected by default
      Provider.of<JobProvider>(context, listen: false).setFilterStatus('all');
    });
    _connSub = ConnectivityService.instance.onStatusChange.listen((online) {
      if (online && mounted) {
        // If there is no queued work and not currently syncing, refresh immediately
        final hasQueue = OfflineQueueService.instance.queue.isNotEmpty;
        if (!hasQueue && !SyncService.instance.isSyncing) {
          Provider.of<JobProvider>(context, listen: false).loadJobs();
        }
        // Otherwise, wait for sync completion signal
      }
    });
    _syncSub = SyncService.instance.onSyncing.listen((syncing) {
      if (!syncing && mounted && ConnectivityService.instance.isOnline) {
        _refreshAfterSync();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _connSub?.cancel();
    _syncSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // floatingActionButton: _currentIndex == 0
      //     ? FloatingActionButton(
      //         onPressed: () async {
      //           final created = await Navigator.push(
      //             context,
      //             MaterialPageRoute(builder: (_) => const CreateJobScreen()),
      //           );
      //           if (created == true && mounted) {
      //             Provider.of<JobProvider>(context, listen: false).loadJobs();
      //           }
      //         },
      //         child: const Icon(Icons.add),
      //       )
      //     : null,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          const ProcedureScreen(),
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
          final total = jobProvider.jobs.length;
          final pending = jobProvider.pendingJobs.length;
          final accepted = jobProvider.acceptedJobs.length;
          final inProgress = jobProvider.inProgressJobs.length;
          final onHold = jobProvider.onHoldJobs.length;
          final active = accepted + inProgress + onHold; // Combined active jobs
          final completed = jobProvider.completedJobs.length;

          // Build filtered list locally so search can include id/customer/vehicle
          final all = List<Job>.from(jobProvider.jobs);
          final q = _searchController.text.trim().toLowerCase();
          List<Job> list = q.isEmpty
              ? all
              : all.where((j) {
                  final hay = [
                    j.id,
                    j.jobName,
                    j.description,
                    j.customer.name,
                    j.vehicle?.plateNo ?? '',
                    [
                      j.vehicle?.brand,
                      j.vehicle?.model,
                      if (j.vehicle?.year != null) j.vehicle!.year.toString(),
                    ].where((e) => (e ?? '').toString().isNotEmpty).join(' '),
                  ].join(' ').toLowerCase();
                  return hay.contains(q);
                }).toList();



          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + Subtitle
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        Icon(Icons.build, color: AppColors.primary, size: 28),
                        const SizedBox(width: 4),
                        Text('Job Dashboard', style: AppTextStyles.headline1),
                        const Spacer(), // 把按钮推到右边
                        IconButton(
                          icon: const Icon(Icons.add, color: Colors.blue),
                          onPressed: () async {
                            final created = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreateJobScreen(),
                              ),
                            );
                            if (created == true && mounted) {
                              Provider.of<JobProvider>(
                                context,
                                listen: false,
                              ).loadJobs();
                            }
                          },
                        ),
                      ],
                    ),
                    // Text('Job Dashboard', style: AppTextStyles.headline1),
                    // const SizedBox(height: 4),
                    Builder(
                      builder: (context) {
                        final offline = Provider.of<JobProvider>(
                          context,
                        ).isOffline;
                        return offline
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.15),
                                  border: Border.all(
                                    color: Colors.orange.withOpacity(0.5),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Offline',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink();
                      },
                    ),
                    // Text(
                    //   'Manage your assigned repair jobs',
                    //   style: AppTextStyles.body2,
                    // ),
                  ],
                ),
              ),

              // Stat cards (responsive)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Overview', style: AppTextStyles.headline2),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _JobFilterCard(
                            title: 'Total Jobs',
                            count: total,
                            icon: Icons.apps,
                            color: AppColors.primary,
                            filterValue: 'all',
                            isSelected: _selectedFilter == 'all',
                            onTap: () => _onFilterTap('all'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _JobFilterCard(
                            title: 'Pending',
                            count: pending,
                            icon: Icons.hourglass_empty,
                            color: AppColors.warning,
                            filterValue: 'pending',
                            isSelected: _selectedFilter == 'pending',
                            onTap: () => _onFilterTap('pending'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _JobFilterCard(
                            title: 'In Progress',
                            count: active,
                            icon: Icons.play_circle,
                            color: AppColors.info,
                            filterValue: 'active',
                            isSelected: _selectedFilter == 'active',
                            onTap: () => _onFilterTap('active'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _JobFilterCard(
                            title: 'Completed',
                            count: completed,
                            icon: Icons.check_circle,
                            color: AppColors.success,
                            filterValue: 'completed',
                            isSelected: _selectedFilter == 'completed',
                            onTap: () => _onFilterTap('completed'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 0),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Job List', style: AppTextStyles.headline2),
                    const SizedBox(height: 4),
                  ],
                ),
              ),

              // Search + Filters
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 16),
              //   child: Container(
              //     padding: const EdgeInsets.all(12),
              //     decoration: BoxDecoration(
              //       color: AppColors.surface,
              //       borderRadius: BorderRadius.circular(12),
              //       boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))],
              //     ),
              //     child: Column(
              //       children: [
              //         Row(
              //           children: [
              //             Expanded(
              //               child: TextField(
              //                 controller: _searchController,
              //                 decoration: const InputDecoration(
              //                   hintText: 'Search by job ID, customer, or vehicle...',
              //                   prefixIcon: Icon(Icons.search),
              //                   isDense: true,
              //                   border: OutlineInputBorder(borderSide: BorderSide.none),
              //                 ),
              //                 onChanged: (v) {
              //                   setState(() {});
              //                 },
              //               ),
              //             ),
              //             IconButton(
              //               tooltip: 'Clear',
              //               onPressed: () {
              //                 _searchController.clear();
              //                 setState(() {});
              //               },
              //               icon: const Icon(Icons.clear),
              //             ),
              //           ],
              //         ),
              //         const SizedBox(height: 8),
              //         SingleChildScrollView(
              //           scrollDirection: Axis.horizontal,
              //           child: Row(
              //             children: [
              //               // Status filter
              //               _PillDropdown<String>(
              //                 width: 140,
              //                 value: _statusFilter,
              //                 items: const [
              //                   DropdownMenuItem(value: 'all', child: Text('All Status')),
              //                   DropdownMenuItem(value: 'pending', child: Text('Pending')),
              //                   DropdownMenuItem(value: 'inProgress', child: Text('In Progress')),
              //                   DropdownMenuItem(value: 'onHold', child: Text('On Hold')),
              //                   DropdownMenuItem(value: 'completed', child: Text('Completed')),
              //                 ],
              //                 onChanged: (v) {
              //                   if (v == null) return;
              //                   setState(() => _statusFilter = v);
              //                   Provider.of<JobProvider>(context, listen: false).setFilterStatus(v);
              //                 },
              //               ),
              //               const SizedBox(width: 8),
              //               // Priority filter
              //               _PillDropdown<String>(
              //                 width: 130,
              //                 value: _priorityFilter,
              //                 items: const [
              //                   DropdownMenuItem(value: 'all', child: Text('All Priority')),
              //                   DropdownMenuItem(value: 'low', child: Text('Low')),
              //                   DropdownMenuItem(value: 'medium', child: Text('Medium')),
              //                   DropdownMenuItem(value: 'high', child: Text('High')),
              //                 ],
              //                 onChanged: (v) => setState(() => _priorityFilter = v ?? 'all'),
              //               ),
              //               const SizedBox(width: 8),
              //               // Sort
              //               _PillDropdown<String>(
              //                 width: 120,
              //                 value: _sortBy,
              //                 items: const [
              //                   DropdownMenuItem(value: 'latest', child: Text('Latest')),
              //                   DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
              //                 ],
              //                 onChanged: (v) => setState(() => _sortBy = v ?? 'latest'),
              //               ),
              //             ],
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 3),

              // List
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
                            Text(
                              'Error loading jobs',
                              style: AppTextStyles.headline2,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              jobProvider.error!,
                              style: AppTextStyles.body2,
                              textAlign: TextAlign.center,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
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

                    if (jobProvider.filteredJobs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No jobs found',
                            style: AppTextStyles.body2,
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => Provider.of<JobProvider>(
                        context,
                        listen: false,
                      ).loadJobs(),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: jobProvider.filteredJobs.length,
                        itemBuilder: (context, index) {
                          final job = jobProvider.filteredJobs[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DashboardJobCard(
                              job: job,
                              onTap: () {
                                Provider.of<JobProvider>(
                                  context,
                                  listen: false,
                                ).selectJob(job);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        JobDetailsScreen(jobId: job.id),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  void _onFilterTap(String filterValue) {
    setState(() {
      _selectedFilter = filterValue;
    });
    Provider.of<JobProvider>(context, listen: false).setFilterStatus(filterValue);
  }

}
class _JobFilterCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final String filterValue;
  final bool isSelected;
  final VoidCallback onTap;

  const _JobFilterCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.filterValue,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 14),
              ),
              // Count
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : AppColors.textPrimary,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Small stat card widget
class FancyStatCard extends StatelessWidget {
  final String title;
  final String value;
  // final String description;
  final IconData icon;
  final List<Color> gradientColors;

  const FancyStatCard({
    super.key,
    required this.title,
    required this.value,
    // required this.description,
    required this.icon,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Icon(icon, size: 24, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headline2,
                  ),
                  const SizedBox(height: 2),
                  // Text(
                  //   description,
                  //   maxLines: 1,
                  //   overflow: TextOverflow.ellipsis,
                  //   style: AppTextStyles.body2,
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple pill-styled dropdown used in the filter row
class _PillDropdown<T> extends StatelessWidget {
  final double width;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _PillDropdown({
    required this.width,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          items: items,
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down),
          style: AppTextStyles.body2,
        ),
      ),
    );
  }
}

// Compact job tile matching dashboard style
class DashboardJobTile extends StatelessWidget {
  final Job job;
  final VoidCallback onTap; //没有参数、没有返回值的函数类型 a variable can store function

  const DashboardJobTile({super.key, required this.job, required this.onTap});

  bool get _isOverdue {
    if (job.status == JobStatus.completed) return false;
    final now = DateTime.now();
    final base = job.startTime ?? job.createdAt;
    final minutes = job.estimatedDuration ?? 0;
    if (minutes > 0) {
      return now.isAfter(base.add(Duration(minutes: minutes)));
    }
    // fallback: older than 24h
    return now.difference(base).inHours > 24;
  }

  String get _estimateLabel {
    final m = job.estimatedDuration;
    if (m == null || m <= 0) return 'Est. —';
    final h = (m / 60).floor();
    final rem = m % 60;
    if (h > 0 && rem == 0) return 'Est. ${h}h';
    if (h > 0) return 'Est. ${h}h ${rem}m';
    return 'Est. ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = JobStatusHelper.getStatusColor(job.status);
    final statusText = JobStatusHelper.getStatusText(job.status);
    final priority = (job.priority ?? '').isNotEmpty
        ? job.priority!.toLowerCase()
        : (job.status == JobStatus.onHold
              ? 'high'
              : job.status == JobStatus.inProgress
              ? 'medium'
              : 'low');

    Color _priorityColor() {
      switch (priority) {
        case 'high':
          return AppColors.error;
        case 'medium':
          return AppColors.warning;
        case 'low':
        default:
          return AppColors.info;
      }
    }

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: id + chips + overdue
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(job.id, style: AppTextStyles.headline2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _priorityColor(),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$priority priority',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          if (_isOverdue)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Overdue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(_estimateLabel, style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Customer + vehicle
              Row(
                children: [
                  const Icon(
                    Icons.person,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      job.customer.name,
                      style: AppTextStyles.body2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.directions_car,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      [
                            job.vehicle?.brand,
                            job.vehicle?.model,
                            if (job.vehicle?.year != null)
                              job.vehicle!.year.toString(),
                          ]
                          .where((e) => (e ?? '').toString().isNotEmpty)
                          .join(' ')
                          .trim(),
                      style: AppTextStyles.body2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${job.vehicle?.plateNo ?? '-'})',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Text(job.description, style: AppTextStyles.body2),

              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: onTap, //当按钮被按下时，执行我传进来的 onTap 函数
                  child: const Text('View Details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
