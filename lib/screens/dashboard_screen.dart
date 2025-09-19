import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/job_provider.dart';
import '../utils/app_utils.dart';
import '../models/job.dart';
import 'task_screen.dart';
import 'procedure_screen.dart';
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

  // Dashboard filters
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'all';
  String _priorityFilter = 'all';
  String _sortBy = 'latest'; // latest | oldest

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<JobProvider>(context, listen: false).loadJobs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
          const ProcedureScreen(),
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
          final inProgress = jobProvider.inProgressJobs.length;
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
                    [j.vehicle?.brand, j.vehicle?.model, if (j.vehicle?.year != null) j.vehicle!.year.toString()]
                        .where((e) => (e ?? '').toString().isNotEmpty)
                        .join(' '),
                  ].join(' ').toLowerCase();
                  return hay.contains(q);
                }).toList();

          // Status filter
          if (_statusFilter != 'all') {
            JobStatus? s;
            switch (_statusFilter) {
              case 'pending':
                s = JobStatus.pending; break;
              case 'inProgress':
                s = JobStatus.inProgress; break;
              case 'onHold':
                s = JobStatus.onHold; break;
              case 'completed':
                s = JobStatus.completed; break;
            }
            if (s != null) {
              list = list.where((j) => j.status == s).toList();
            }
          }

          // Priority filter
          if (_priorityFilter != 'all') {
            list = list.where((j) => (_derivePriority(j)).toLowerCase() == _priorityFilter).toList();
          }

          // Sort
          if (_sortBy == 'latest') {
            list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          } else {
            list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + Subtitle
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Job Dashboard', style: AppTextStyles.headline1),
                    const SizedBox(height: 4),
                    Text('Manage your assigned repair jobs', style: AppTextStyles.body2),
                  ],
                ),
              ),

              // Stat cards (responsive)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 420;
                    final cross = isCompact ? 2 : 4;
                    final itemHeight = isCompact ? 112.0 : 108.0; // fixed safe height to prevent overflow
                    final items = [
                      _StatCard(label: 'Total Jobs', value: '$total', icon: Icons.build, iconBg: AppColors.surface),
                      _StatCard(label: 'Pending', value: '$pending', icon: Icons.schedule, iconBg: AppColors.surface),
                      _StatCard(label: 'In Progress', value: '$inProgress', icon: Icons.warning_amber_rounded, iconBg: AppColors.surface),
                      _StatCard(label: 'Completed', value: '$completed', icon: Icons.check_circle, iconBg: AppColors.surface),
                    ];

                    return GridView.builder(
                      padding: EdgeInsets.zero,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cross,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        mainAxisExtent: itemHeight,
                      ),
                      itemCount: items.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (_, i) => items[i],
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Search + Filters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Search by job ID, customer, or vehicle...',
                                prefixIcon: Icon(Icons.search),
                                isDense: true,
                                border: OutlineInputBorder(borderSide: BorderSide.none),
                              ),
                              onChanged: (v) {
                                setState(() {});
                              },
                            ),
                          ),
                          IconButton(
                            tooltip: 'Clear',
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.clear),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Status filter
                            _PillDropdown<String>(
                              width: 140,
                              value: _statusFilter,
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('All Status')),
                                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                                DropdownMenuItem(value: 'inProgress', child: Text('In Progress')),
                                DropdownMenuItem(value: 'onHold', child: Text('On Hold')),
                                DropdownMenuItem(value: 'completed', child: Text('Completed')),
                              ],
                              onChanged: (v) {
                                if (v == null) return;
                                setState(() => _statusFilter = v);
                                Provider.of<JobProvider>(context, listen: false).setFilterStatus(v);
                              },
                            ),
                            const SizedBox(width: 8),
                            // Priority filter
                            _PillDropdown<String>(
                              width: 130,
                              value: _priorityFilter,
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('All Priority')),
                                DropdownMenuItem(value: 'low', child: Text('Low')),
                                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                                DropdownMenuItem(value: 'high', child: Text('High')),
                              ],
                              onChanged: (v) => setState(() => _priorityFilter = v ?? 'all'),
                            ),
                            const SizedBox(width: 8),
                            // Sort
                            _PillDropdown<String>(
                              width: 120,
                              value: _sortBy,
                              items: const [
                                DropdownMenuItem(value: 'latest', child: Text('Latest')),
                                DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
                              ],
                              onChanged: (v) => setState(() => _sortBy = v ?? 'latest'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

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
                            Text('Error loading jobs', style: AppTextStyles.headline2),
                            const SizedBox(height: 8),
                            Text(jobProvider.error!, style: AppTextStyles.body2, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: () => jobProvider.loadJobs(), child: const Text('Retry')),
                          ],
                        ),
                      );
                    }

                    if (list.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text('No jobs found', style: AppTextStyles.body2),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => Provider.of<JobProvider>(context, listen: false).loadJobs(),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final job = list[index];
                          return DashboardJobTile(
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
          );
        },
      ),
    );
  }

  // Derive a simple priority if not provided
  String _derivePriority(Job job) {
    final p = job.priority?.toLowerCase();
    if (p != null && p.isNotEmpty) return p;
    // Basic heuristic: onHold -> high, inProgress -> medium, completed -> low
    if (job.status == JobStatus.onHold) return 'high';
    if (job.status == JobStatus.inProgress) return 'medium';
    if (job.status == JobStatus.completed) return 'low';
    return 'medium';
  }
}

// Small stat card widget
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconBg;

  const _StatCard({required this.label, required this.value, required this.icon, required this.iconBg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(value, style: AppTextStyles.headline2, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
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

  const _PillDropdown({required this.width, required this.value, required this.items, required this.onChanged});

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
  final VoidCallback onTap;//没有参数、没有返回值的函数类型 a variable can store function

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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(12)),
                          child: Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: _priorityColor(), borderRadius: BorderRadius.circular(12)),
                          child: Text('$priority priority', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          if (_isOverdue)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(12)),
                              child: const Text('Overdue', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
                  const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(child: Text(job.customer.name, style: AppTextStyles.body2, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 12),
                  const Icon(Icons.directions_car, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      [job.vehicle?.brand, job.vehicle?.model, if (job.vehicle?.year != null) job.vehicle!.year.toString()]
                          .where((e) => (e ?? '').toString().isNotEmpty)
                          .join(' ')
                          .trim(),
                      style: AppTextStyles.body2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('(${job.vehicle?.plateNo ?? '-'})', style: AppTextStyles.caption),
                ],
              ),

              const SizedBox(height: 8),
              Text(job.description, style: AppTextStyles.body2),

              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: onTap, //当按钮被按下时，执行我传进来的 onTap 函数
                  child: const Text('View Details'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
