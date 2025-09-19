import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/job_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_utils.dart';
import '../models/job.dart';
import 'job_details_screen.dart';
import '../widgets/app_header.dart';
import '../widgets/dashboard_job_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';
  DateTimeRange? _dateRange;

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
      // appBar: AppBar(
      //   title: const Text('Search'),
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   foregroundColor: Colors.black,
      //   centerTitle: true,
      // ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + Subtitle
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Search', style: AppTextStyles.headline1),
                  // const SizedBox(height: 4),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Job name...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      Provider.of<JobProvider>(
                        context,
                        listen: false,
                      ).searchJobs('');
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                onChanged: (value) {
                  Provider.of<JobProvider>(
                    context,
                    listen: false,
                  ).searchJobs(value);
                },
              ),
            ),

            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pending', 'pending'),
                    const SizedBox(width: 8),
                    _buildFilterChip('In Progress', 'inProgress'),
                    const SizedBox(width: 8),
                    _buildFilterChip('On Hold', 'onHold'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Completed', 'completed'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Declined', 'declined'),
                    const SizedBox(width: 8),
                    _buildDateChip(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Search Results
            Expanded(
              child: Consumer<JobProvider>(
                builder: (context, jobProvider, child) {
                  if (jobProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final jobs = jobProvider.filteredJobs;

                  if (jobs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            jobProvider.searchQuery.isEmpty
                                ? 'No jobs found'
                                : 'No results found for "${jobProvider.searchQuery}"',
                            style: AppTextStyles.headline2,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search terms or filters',
                            style: AppTextStyles.body2,
                            textAlign: TextAlign.center,
                          ),
                        ],
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: jobs.length,
                      itemBuilder: (context, index) {
                        final job = jobs[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12, top: 8),
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
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
        Provider.of<JobProvider>(context, listen: false).setFilterStatus(value);
      },
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildDateChip() {
    final hasRange = _dateRange != null;
    final label = hasRange
        ? _formatRange(_dateRange!)
        : 'Date';
    return InputChip(
      label: Text(label),
      avatar: const Icon(Icons.date_range, size: 18),
      onPressed: _pickDateRange,
      onDeleted: hasRange
          ? () {
              setState(() {
                _dateRange = null;
              });
              Provider.of<JobProvider>(context, listen: false)
                  .setDateRange(null, null);
            }
          : null,
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initial = _dateRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day),
        );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: initial,
    );
    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
      Provider.of<JobProvider>(context, listen: false)
          .setDateRange(picked.start, picked.end);
    }
  }

  String _formatRange(DateTimeRange r) {
    String fmt(DateTime d) {
      final y = d.year.toString().padLeft(4, '0');
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return '$y-$m-$day';
    }
    final s = fmt(r.start);
    final e = fmt(r.end);
    return s == e ? s : '$s → $e';
  }
}
