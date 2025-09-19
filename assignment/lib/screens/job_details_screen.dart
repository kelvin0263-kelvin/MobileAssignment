import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timer_builder/timer_builder.dart';
import '../providers/job_provider.dart';
import '../utils/app_utils.dart';
import '../models/job.dart';
import '../widgets/timer_widget.dart';
import '../widgets/notes_widget.dart';
import '../widgets/pill_segmented_control.dart';
import '../widgets/signature_widget.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'procedure_detail_screen.dart';

class JobDetailsScreen extends StatefulWidget {
  final String jobId;

  const JobDetailsScreen({super.key, required this.jobId});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  bool _isTimerRunning = false;
  DateTime? _timerStartTime;
  Duration _elapsedTime = Duration.zero;
  int _segmentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<JobProvider>(
        context,
        listen: false,
      ).loadJobById(widget.jobId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Consumer<JobProvider>(
        builder: (context, jobProvider, child) {
          final job = jobProvider.selectedJob;

          return Scaffold(
            backgroundColor: AppColors.surface,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(120),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top bar
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: Text(
                              job?.jobName ?? 'Job Details',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // IconButton(
                          //   icon: const Icon(
                          //     Icons.more_vert,
                          //     color: Colors.white,
                          //   ),
                          //   onPressed: _showOptionsDialog,
                          // ),
                        ],
                      ),
                      // Secondary row with id and status chip
                      // Padding(
                      //   padding: const EdgeInsets.symmetric(horizontal: 12),
                      //   child: Row(
                      //     children: [
                      //       Text(
                      //         job?.id ?? widget.jobId,
                      //         style: const TextStyle(color: Colors.white70),
                      //       ),
                      //       const SizedBox(width: 8),
                      //       Container(
                      //         padding: const EdgeInsets.symmetric(
                      //           horizontal: 10,
                      //           vertical: 4,
                      //         ),
                      //         decoration: BoxDecoration(
                      //           color: Colors.white.withOpacity(0.18),
                      //           borderRadius: BorderRadius.circular(12),
                      //         ),
                      //         child: Text(
                      //           job == null
                      //               ? ''
                      //               : JobStatusHelper.getStatusText(job.status),
                      //           style: const TextStyle(
                      //             color: Colors.white,
                      //             fontSize: 12,
                      //             fontWeight: FontWeight.w600,
                      //           ),
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                      const SizedBox(height: 10),
                      // Segmented control for sections
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: PillSegmentedControl(
                          items: const [
                            SegmentItem(
                              icon: Icons.info_outline,
                              label: 'Overview',
                            ),
                            SegmentItem(
                              icon: Icons.check_circle_outline,
                              label: 'Checklist',
                            ),
                            SegmentItem(icon: Icons.access_time, label: 'Time'),
                            SegmentItem(
                              icon: Icons.note_alt_outlined,
                              label: 'Notes',
                            ),
                          ],
                          currentIndex: _segmentIndex,
                          onChanged: (i) {
                            final status = job?.status;
                            final locked =
                                status == JobStatus.pending ||
                                status == JobStatus.declined ||
                                status == null;
                            final allowed = locked ? i == 0 : true;
                            if (allowed) {
                              setState(() => _segmentIndex = i);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Accept the job to access this section',
                                  ),
                                ),
                              );
                            }
                          },
                          textStyle: const TextStyle(fontSize: 10), // 👈 控制字体大小
                        ),
                      ),
                      // const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
            body: _buildBody(jobProvider, job),
            bottomNavigationBar: _buildBottomActionBar(job),
          );
        },
      ),
    );
  }

  Widget _buildBody(JobProvider jobProvider, Job? job) {
    if (jobProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (job == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Job not found', style: AppTextStyles.headline2),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => jobProvider.loadJobById(widget.jobId),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final views = <Widget>[
      _buildOverviewTab(job),
      _buildChecklistTab(job),
      _buildTimeTab(job),
      _buildNotesTab(job),
    ];
    final idx =
        (job.status == JobStatus.pending || job.status == JobStatus.declined)
        ? 0
        : _segmentIndex;
    return views[idx.clamp(0, views.length - 1)];
  }

  Widget _buildOverviewTab(Job job) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildJobHeader(job),
          const SizedBox(height: 16),
          _buildQuickStats(job),
          const SizedBox(height: 16),
          _buildCustomerDetails(job),
          if (job.vehicle != null) ...[
            const SizedBox(height: 16),
            _buildVehicleDetails(job),
          ],
          const SizedBox(height: 16),
          _buildAssignedPartsReadOnly(job),
        ],
      ),
    );
  }

  Widget _buildQuickStats(Job job) {
    final total = job.tasks.length;
    final done = job.tasks
        .where((t) => t.status == JobTaskStatus.completed)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _miniStat('Tasks', '$done/$total', Icons.checklist),
        const SizedBox(height: 12),
        _miniStat('Notes', '${job.notes.length}', Icons.note_alt_outlined),
        const SizedBox(height: 12),
        _miniStat('Parts', '${job.assignedParts.length}', Icons.build),
      ],
    );
  }

  Widget _miniStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: AppTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.body1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistTab(Job job) {
    final tasks = job.tasks;
    final total = tasks.length;
    final done = tasks
        .where(
          (t) =>
              t.status == JobTaskStatus.completed ||
              t.status == JobTaskStatus.skipped,
        )
        .length;
    final progress = total == 0 ? 0.0 : done / total;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text('Task Checklist', style: AppTextStyles.headline2),
              ),

              Expanded(
                child: Align(
                  alignment: Alignment.centerRight, // 👈 靠右
                  child: Text(
                    '$done of $total completed',
                    style: AppTextStyles.caption,
                  ),
                ),
              ),
            ],
          ),
                    const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.divider,
            ),
          ),
          const SizedBox(height: 16),
          if (tasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'No tasks added for this job',
                style: AppTextStyles.body2,
              ),
            )
          else
            ...tasks.map(
              (t) => _TaskItem(
                task: t,
                readOnly: job.status == JobStatus.completed,
                onToggle: (newStatus) {
                  Provider.of<JobProvider>(
                    context,
                    listen: false,
                  ).updateTaskStatus(t.id, newStatus);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeTab(Job job) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimerSection(job),
          const SizedBox(height: 16),
          _buildTimerLog(job),
        ],
      ),
    );
  }

  Widget _buildPartsTab(Job job) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildAssignedParts(job)],
      ),
    );
  }

  Widget _buildNotesTab(Job job) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: NotesWidget(
        jobId: job.id,
        readOnly: job.status == JobStatus.completed,
      ),
    );
  }

  Widget _buildJobHeader(Job job) {
    final statusText = JobStatusHelper.getStatusText(job.status);
    final statusColor = JobStatusHelper.getStatusColor(job.status);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: AppColors.cardGradient,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + status chip
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.jobName,
                    style: AppTextStyles.headline2.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.55)),
                  ),
                  child: Text(
                    statusText,
                    style: AppTextStyles.caption.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (job.description.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(job.description, style: AppTextStyles.body2),
            ],
            if (job.requestedServices.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Requested Services',
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: job.requestedServices
                    .map((s) => _serviceChip(s))
                    .toList(),
              ),
            ],
            if ((job.digitalSignature ?? '').isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Signature',
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _viewSignature(job.digitalSignature!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _imageForPath(
                    job.digitalSignature!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDetails(Job job) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text('Customer', style: AppTextStyles.headline2),
                const Spacer(),
                if (job.vehicle != null)
                  OutlinedButton.icon(
                    onPressed: () {
                      final v = job.vehicle!;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _VehicleHistoryScreen(
                            vehicleId: v.id,
                            plateNo: v.plateNo ?? '-',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.history, size: 14), // 👈 图标再小
                    label: const Text(
                      'Repair History',
                      style: TextStyle(fontSize: 12), // 👈 字体再小
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ), // 👈 内边距小
                      minimumSize: Size.zero, // 👈 允许按钮高度小于默认
                      tapTargetSize:
                          MaterialTapTargetSize.shrinkWrap, // 👈 点击区域缩小
                      shape: const StadiumBorder(),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _labelValue('Name', job.customer.name)),
                const SizedBox(width: 12),
                Expanded(child: _labelValue('Contact', job.customer.contactNo)),
              ],
            ),
            const SizedBox(height: 12),
            _labelValue('Address', job.customer.address),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleDetails(Job job) {
    final v = job.vehicle!;
    final vehicleTitle = [
      v.brand,
      v.model,
      if (v.year != null) v.year.toString(),
    ].where((e) => (e ?? '').toString().isNotEmpty).join(' ').trim();

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Text('Vehicle', style: AppTextStyles.headline2),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _labelValue(
                    'Brand & Model',
                    vehicleTitle.isEmpty ? '-' : vehicleTitle,
                  ),
                ),
                // const SizedBox(width: 12),
                // Expanded(child: _labelValue('Year', v.year?.toString() ?? '-')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _labelValue('Plate Number', v.plateNo ?? '-')),

                const SizedBox(width: 12),
                Expanded(child: _labelValue('Year', v.year?.toString() ?? '-')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _labelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 12, // 👈 改大小
            color: Colors.grey[600], // 👈 改颜色
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? '-' : value,
          style: AppTextStyles.body1.copyWith(
            fontSize: 14, // 👈 改大小
            color: Colors.black, // 👈 改颜色
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value, style: AppTextStyles.body2)),
        ],
      ),
    );
  }

  Widget _buildAssignedParts(Job job) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Assigned Parts', style: AppTextStyles.headline2),
              ],
            ),
            const SizedBox(height: 12),
            if (job.assignedParts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No parts assigned yet',
                  style: AppTextStyles.body2,
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...job.assignedParts.map((part) => _buildPartItem(part)),
          ],
        ),
      ),
    );
  }

  // Read-only version for Overview tab
  Widget _buildAssignedPartsReadOnly(Job job) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Assigned Parts', style: AppTextStyles.headline2),
                const Spacer(),
                Text(
                  '${job.assignedParts.length}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (job.assignedParts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No parts assigned yet',
                  style: AppTextStyles.body2,
                  textAlign: TextAlign.center,
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: job.assignedParts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _buildPartItem(job.assignedParts[i]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartItem(AssignedPart part) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  part.name,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (part.notes != null && part.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(part.notes!, style: AppTextStyles.caption),
                ],
              ],
            ),
          ),
          _chip('Qty: ${part.quantity}', AppColors.primary, filled: true),
        ],
      ),
    );
  }

  // --- UI helpers ---
  Widget _serviceChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(text, style: AppTextStyles.caption),
    );
  }

  Widget _iconDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          SizedBox(
            width: 96,
            child: Text('$label:', style: AppTextStyles.body2),
          ),
          Expanded(child: Text(value, style: AppTextStyles.body2)),
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
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTimerSection(Job job) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Time Tracking', style: AppTextStyles.headline2),
            const SizedBox(height: 12),
            TimerWidget(
              jobId: job.id,
              isRunning: _isTimerRunning,
              readOnly: job.status == JobStatus.completed,
              onStart: () {
                setState(() => _isTimerRunning = true);
                Provider.of<JobProvider>(
                  context,
                  listen: false,
                ).addTimerEvent(job.id, JobTimerAction.start);
              },
              onPause: () {
                setState(() => _isTimerRunning = false);
                Provider.of<JobProvider>(
                  context,
                  listen: false,
                ).addTimerEvent(job.id, JobTimerAction.pause);
              },
              onStop: () {
                setState(() => _isTimerRunning = false);
                Provider.of<JobProvider>(
                  context,
                  listen: false,
                ).addTimerEvent(job.id, JobTimerAction.stop);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerLog(Job job) {
    final timers = List<JobTimerEvent>.from(
      (job.timers as List<JobTimerEvent>? ?? const <JobTimerEvent>[]),
    )..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Log', style: AppTextStyles.headline2),
                const Spacer(),
                Text('${timers.length} entries', style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 8),
            if (timers.isEmpty)
              Text('No time entries yet', style: AppTextStyles.body2)
            else
              ...timers.map(
                (e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        _timerIcon(e.action),
                        size: 18,
                        color: _timerColor(e.action),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _actionLabel(e.action),
                          style: AppTextStyles.body1,
                        ),
                      ),
                      Text(
                        DateHelper.formatDateTime(e.timestamp),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _actionLabel(JobTimerAction a) {
    switch (a) {
      case JobTimerAction.start:
        return 'Started';
      case JobTimerAction.pause:
        return 'Paused';
      case JobTimerAction.resume:
        return 'Resumed';
      case JobTimerAction.stop:
        return 'Stopped';
    }
  }

  IconData _timerIcon(JobTimerAction a) {
    switch (a) {
      case JobTimerAction.start:
        return Icons.play_arrow;
      case JobTimerAction.pause:
        return Icons.pause;
      case JobTimerAction.resume:
        return Icons.play_circle_fill;
      case JobTimerAction.stop:
        return Icons.stop;
    }
  }

  Color _timerColor(JobTimerAction a) {
    switch (a) {
      case JobTimerAction.start:
      case JobTimerAction.resume:
        return AppColors.success;
      case JobTimerAction.pause:
        return AppColors.warning;
      case JobTimerAction.stop:
        return AppColors.error;
    }
  }

  void _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
  }

  Widget _buildActionButtons(Job job) {
    return const SizedBox.shrink();
  }

  Widget _buildBottomActionBar(Job? job) {
    if (job == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          if (job.status == JobStatus.pending) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _updateJobStatus(JobStatus.declined),
                icon: const Icon(Icons.close_rounded),
                label: const Text('Decline'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _updateJobStatus(JobStatus.accepted),
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Accept'),
              ),
            ),
          ] else if (job.status == JobStatus.declined) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _updateJobStatus(JobStatus.accepted),
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Accept'),
              ),
            ),
          ] else if (job.status == JobStatus.accepted) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _updateJobStatus(JobStatus.inProgress),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Job'),
              ),
            ),
          ] else if (job.status == JobStatus.inProgress) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _updateJobStatus(JobStatus.onHold),
                icon: const Icon(Icons.pause_circle_filled_rounded),
                label: const Text('On Hold'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: const BorderSide(color: AppColors.warning),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed:
                    (job.tasks.isEmpty ||
                        job.tasks.every(
                          (t) => t.status == JobTaskStatus.completed,
                        ))
                    ? () => _showCompleteJobDialog()
                    : null,
                icon: const Icon(Icons.check_rounded),
                label: const Text('Complete'),
              ),
            ),
          ] else if (job.status == JobStatus.onHold) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _updateJobStatus(JobStatus.inProgress),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Resume'),
              ),
            ),
          ] else if (job.status == JobStatus.completed) ...[
            if ((job.digitalSignature ?? '').isEmpty)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showSignatureDialog(),
                  icon: const Icon(Icons.draw_rounded),
                  label: const Text('Sign'),
                ),
              )
            else
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewSignature(job.digitalSignature!),
                  icon: const Icon(Icons.visibility_rounded),
                  label: const Text('View Signature'),
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _viewSignature(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: InteractiveViewer(
          child: _imageForPath(url, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _imageForPath(
    String path, {
    double? height,
    double? width,
    BoxFit? fit,
  }) {
    try {
      if (path.startsWith('http')) {
        return Image.network(
          path,
          height: height,
          width: width,
          fit: fit,
          errorBuilder: (_, __, ___) => _broken(),
        );
      }
      final file = path.startsWith('file://')
          ? File.fromUri(Uri.parse(path))
          : File(path);
      return Image.file(
        file,
        height: height,
        width: width,
        fit: fit,
        errorBuilder: (_, __, ___) => _broken(),
      );
    } catch (_) {
      return _broken();
    }
  }

  Widget _broken() => Container(
    height: 120,
    width: double.infinity,
    color: AppColors.background,
    alignment: Alignment.center,
    child: const Icon(Icons.broken_image, color: AppColors.textSecondary),
  );

  void _startTimer() {
    setState(() {
      _isTimerRunning = true;
      _timerStartTime = DateTime.now();
    });
  }

  void _pauseTimer() {
    setState(() {
      _isTimerRunning = false;
      if (_timerStartTime != null) {
        _elapsedTime += DateTime.now().difference(_timerStartTime!);
      }
    });
  }

  void _stopTimer() {
    setState(() {
      _isTimerRunning = false;
      _timerStartTime = null;
      _elapsedTime = Duration.zero;
    });
  }

  void _updateJobStatus(JobStatus status) {
    final jobProvider = Provider.of<JobProvider>(context, listen: false);
    jobProvider.updateJobStatus(widget.jobId, status);
  }

  // void _showOptionsDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Job Options'),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           ListTile(
  //             leading: const Icon(Icons.edit),
  //             title: const Text('Edit Job'),
  //             onTap: () {
  //               Navigator.pop(context);
  //             },
  //           ),
  //           ListTile(
  //             leading: const Icon(Icons.share),
  //             title: const Text('Share Job Details'),
  //             onTap: () {
  //               Navigator.pop(context);
  //             },
  //           ),
  //           ListTile(
  //             leading: const Icon(Icons.print),
  //             title: const Text('Print Job Details'),
  //             onTap: () {
  //               Navigator.pop(context);
  //             },
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  void _showAddPartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Part'),
        content: const Text(
          'Part addition functionality will be implemented here.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showCompleteJobDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Job'),
        content: const Text(
          'Are you sure you want to mark this job as completed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateJobStatus(JobStatus.completed);
            },
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _showSignatureDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SignatureWidget(
          jobId: widget.jobId,
          onSignatureComplete: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

class _VehicleHistoryScreen extends StatefulWidget {
  final String vehicleId;
  final String plateNo;

  const _VehicleHistoryScreen({required this.vehicleId, required this.plateNo});

  @override
  State<_VehicleHistoryScreen> createState() => _VehicleHistoryScreenState();
}

class _VehicleHistoryScreenState extends State<_VehicleHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<JobProvider>(
        context,
        listen: false,
      ).loadJobsByVehicle(widget.vehicleId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text('History: ${widget.plateNo}'),
      ),
      body: Consumer<JobProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final jobs = provider.vehicleHistory;
          if (jobs.isEmpty) {
            return Center(
              child: Text(
                'No repair history found',
                style: AppTextStyles.body2,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: jobs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final j = jobs[index];
              final services = j.requestedServices.join(', ');
              return Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  title: Text(
                    j.jobName,
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        services.isEmpty ? 'No services listed' : services,
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${DateHelper.formatDateTime(j.startTime ?? j.createdAt)}  •  ${JobStatusHelper.getStatusText(j.status)}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  final JobTask task;
  final ValueChanged<JobTaskStatus> onToggle;
  final bool readOnly;

  const _TaskItem({
    required this.task,
    required this.onToggle,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == JobTaskStatus.completed;
    final int? procedureId = int.tryParse(task.procedureId ?? '');
    return Card(
      elevation: 1.5,
      color: Colors.white,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Checkbox(
              value: isDone,
              onChanged: readOnly
                  ? null
                  : (v) => onToggle(
                      v == true
                          ? JobTaskStatus.completed
                          : JobTaskStatus.pending,
                    ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.description, style: AppTextStyles.body1),
                  if (task.status == JobTaskStatus.inProgress)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('In progress', style: AppTextStyles.caption),
                    ),
                  if (task.status == JobTaskStatus.skipped)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Skipped', style: AppTextStyles.caption),
                    ),
                ],
              ),
            ),
            if (procedureId != null)
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ProcedureDetailScreen(procedureId: procedureId),
                    ),
                  );
                },
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Procedure'),
              ),
            if (procedureId != null) const SizedBox(width: 8),
            if ((task.tutorialUrl ?? '').isNotEmpty)
              OutlinedButton.icon(
                onPressed: () =>
                    Clipboard.setData(
                      ClipboardData(text: task.tutorialUrl!),
                    ).then((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tutorial link copied')),
                      );
                    }),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Tutorial'),
              ),
          ],
        ),
      ),
    );
  }
}
