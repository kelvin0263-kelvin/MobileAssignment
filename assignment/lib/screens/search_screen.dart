import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../providers/job_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_utils.dart';
import '../models/job.dart';
import 'job_details_screen.dart';
import '../widgets/app_header.dart';
import '../widgets/dashboard_job_card.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';
import '../services/offline_queue_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';
  String _selectedPriority = 'all';
  DateTimeRange? _dateRange;
  StreamSubscription<bool>? _connSub;
  StreamSubscription<bool>? _syncSub;
  Future<void> _refreshAfterSync() async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    Provider.of<JobProvider>(context, listen: false).loadJobs();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<JobProvider>(context, listen: false).loadJobs();
    });
    _connSub = ConnectivityService.instance.onStatusChange.listen((online) {
      if (online && mounted) {
        final hasQueue = OfflineQueueService.instance.queue.isNotEmpty;
        if (!hasQueue && !SyncService.instance.isSyncing) {
          Provider.of<JobProvider>(context, listen: false).loadJobs();
        }
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
                  Row(
                    children: [
                      Icon(Icons.build, color: AppColors.primary, size: 28),
                      const SizedBox(width: 4),
                      Text(
                        'Search',
                        style: AppTextStyles.headline1,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search Bar + Filter button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by job name... ',
                        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                        suffixIcon: IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            Provider.of<JobProvider>(
                              context,
                              listen: false,
                            ).searchJobs('');
                          },
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        filled: true,
                        fillColor: AppColors.surface,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                      onChanged: (value) {
                        Provider.of<JobProvider>(
                          context,
                          listen: false,
                        ).searchJobs(value);
                      },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _FilterButton(onPressed: _openFilterSheet),
                ],
              ),
            ),

            // Filter chips removed in favor of filter sheet

            const SizedBox(height: 16),

            // Search Results
            Expanded(
              child: Consumer<JobProvider>(
                builder: (context, jobProvider, child) {
                  if (jobProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  List<Job> jobs = jobProvider.filteredJobs;
                  if (_selectedPriority != 'all') {
                    jobs = jobs
                        .where((j) => (j.priority ?? '').toLowerCase() == _selectedPriority)
                        .toList();
                  }

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

  void _openFilterSheet() {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    final now = DateTime.now();
    int amount = 0; // last amount
    String unit = 'days';
    String selectedStatus = _selectedFilter; // all | pending | accepted | inProgress | onHold | completed
    String selectedPriority = _selectedPriority; // all | low | medium | high | urgent
    DateTimeRange? tempRange = _dateRange;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Add filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Status
                      _sectionHeader('Status'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in const [
                            ['All','all'],
                            ['Pending','pending'],
                            ['Accepted','accepted'],
                            ['In Progress','inProgress'],
                            ['On Hold','onHold'],
                            ['Completed','completed'],
                          ])
                            ChoiceChip(
                              label: Text(s[0] as String),
                              selected: selectedStatus == (s[1] as String),
                              onSelected: (_) => setModalState(() => selectedStatus = s[1] as String),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Priority
                      _sectionHeader('Priority'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final p in const [
                            ['Any','all'],
                            ['Low','low'],
                            ['Medium','medium'],
                            ['High','high'],
                            ['Urgent','urgent'],
                          ])
                            ChoiceChip(
                              label: Text(p[0] as String),
                              selected: selectedPriority == (p[1] as String),
                              onSelected: (_) => setModalState(() => selectedPriority = p[1] as String),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Date
                      _sectionHeader('Date'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Last'),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 120,
                            child: TextField(
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                hintText: 'Enter amount',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                filled: true,
                                fillColor: AppColors.surface,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.divider),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.primary),
                                ),
                              ),
                              onChanged: (v) => setModalState(() => amount = int.tryParse(v) ?? 0),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 140,
                            child: DropdownButtonFormField<String>(
                              value: unit,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(value: 'days', child: Text('days')),
                                DropdownMenuItem(value: 'weeks', child: Text('weeks')),
                                DropdownMenuItem(value: 'months', child: Text('months')),
                                DropdownMenuItem(value: 'years', child: Text('years')),
                              ],
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                filled: true,
                                fillColor: AppColors.surface,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.divider),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.primary),
                                ),
                              ),
                              onChanged: (v) => setModalState(() => unit = v ?? 'days'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tempRange == null
                                  ? 'No custom range selected'
                                  : '${_formatRange(tempRange!)}',
                              style: AppTextStyles.caption,
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                                initialDateRange: tempRange ?? DateTimeRange(start: now, end: now),
                              );
                              if (picked != null) {
                                setModalState(() => tempRange = picked);
                              }
                            },
                            child: const Text('Pick date range'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Actions
                      ElevatedButton(
                        onPressed: () {
                          // Apply status
                          setState(() => _selectedFilter = selectedStatus);
                          jobProvider.setFilterStatus(selectedStatus);

                          // Apply priority (local)
                          setState(() => _selectedPriority = selectedPriority);

                          // Apply date
                          if (tempRange != null) {
                            jobProvider.setDateRange(tempRange!.start, tempRange!.end);
                            setState(() => _dateRange = tempRange);
                          } else if (amount > 0) {
                            final from = _dateFromAmountUnit(now, amount, unit);
                            jobProvider.setDateRange(from, now);
                            setState(() => _dateRange = DateTimeRange(start: from, end: now));
                          } else {
                            // Keep as-is
                          }

                          Navigator.pop(context);
                        },
                        child: const Text('Apply'),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedFilter = 'all';
                              _selectedPriority = 'all';
                              _dateRange = null;
                            });
                            jobProvider.setFilterStatus('all');
                            jobProvider.setDateRange(null, null);
                            Navigator.pop(context);
                          },
                          child: const Text('Clear all'),
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  DateTime _dateFromAmountUnit(DateTime now, int amount, String unit) {
    switch (unit) {
      case 'weeks':
        return now.subtract(Duration(days: amount * 7));
      case 'months':
        return now.subtract(Duration(days: amount * 30));
      case 'years':
        return now.subtract(Duration(days: amount * 365));
      case 'days':
      default:
        return now.subtract(Duration(days: amount));
    }
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

  Widget _buildPriorityFilterChip(String label, String value) {
    final isSelected = _selectedPriority == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedPriority = value;
        });
      },
      selectedColor: AppColors.info,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  // Small filter button used in the search bar
  Widget _FilterButton({required VoidCallback onPressed}) {
    return SizedBox(
      height: 48,
      width: 48,
      child: Container
        (
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: const Icon(Icons.tune, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  // Section header used in filter sheet

  Widget _buildDateChip() {
    final hasRange = _dateRange != null;
    final label = hasRange ? _formatRange(_dateRange!) : 'Date';
    return InputChip(
      label: Text(label),
      avatar: const Icon(Icons.date_range, size: 18),
      onPressed: _pickDateRange,
      onDeleted: hasRange
          ? () {
              setState(() {
                _dateRange = null;
              });
              Provider.of<JobProvider>(
                context,
                listen: false,
              ).setDateRange(null, null);
            }
          : null,
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initial =
        _dateRange ??
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
      Provider.of<JobProvider>(
        context,
        listen: false,
      ).setDateRange(picked.start, picked.end);
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

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
    );
  }
}
