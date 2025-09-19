import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/job_provider.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'all';
  String _priorityFilter = 'all';
  String _sortBy = 'latest';

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
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(subtitle: 'Task'),
            
            // Search and Filter Section
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
                    // Search Bar
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
                            onChanged: (value) {
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
                    // Filter Row
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

                  // Build filtered list
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

                  if (list.isEmpty) {
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
                            'No jobs found',
                            style: AppTextStyles.headline2,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Try adjusting your search or filters',
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
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final job = list[index];
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
