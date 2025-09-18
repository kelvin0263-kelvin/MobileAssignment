import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timer_builder/timer_builder.dart';
import '../providers/job_provider.dart';
import '../utils/app_utils.dart';
import '../models/job.dart';
import '../widgets/timer_widget.dart';
import '../widgets/notes_widget.dart';
import '../widgets/signature_widget.dart';
import 'package:flutter/services.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<JobProvider>(context, listen: false).loadJobById(widget.jobId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Consumer<JobProvider>(
        builder: (context, jobProvider, child) {
          final job = jobProvider.selectedJob;

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              title: Text(job?.id ?? widget.jobId),
              actions: [
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    _showOptionsDialog();
                  },
                ),
              ],
              bottom: const TabBar(
                isScrollable: false,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: [
                  Tab(icon: Icon(Icons.info_outline), text: 'Overview'),
                  Tab(icon: Icon(Icons.check_circle_outline), text: 'Checklist'),
                  Tab(icon: Icon(Icons.access_time), text: 'Time'),
                  Tab(icon: Icon(Icons.build), text: 'Parts'),
                  Tab(icon: Icon(Icons.note_alt_outlined), text: 'Notes'),
                ],
              ),
            ),
            body: _buildBody(jobProvider, job),
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
            Text(
              'Job not found',
              style: AppTextStyles.headline2,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => jobProvider.loadJobById(widget.jobId),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      children: [
        _buildOverviewTab(job),
        _buildChecklistTab(job),
        _buildTimeTab(job),
        _buildPartsTab(job),
        _buildNotesTab(job),
      ],
    );
  }

  Widget _buildOverviewTab(Job job) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildJobHeader(job),
          const SizedBox(height: 24),
          _buildCustomerDetails(job),
          const SizedBox(height: 24),
          _buildActionButtons(job),
        ],
      ),
    );
  }

  Widget _buildChecklistTab(Job job) {
    final tasks = job.tasks;
    final total = tasks.length;
    final done = tasks.where((t) => t.status == JobTaskStatus.completed || t.status == JobTaskStatus.skipped).length;
    final progress = total == 0 ? 0.0 : done / total;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Task Checklist', style: AppTextStyles.headline2),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: AppColors.divider),
                ),
              ),
              const SizedBox(width: 12),
              Text('$done of $total completed', style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 16),
          if (tasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
              child: Text('No tasks added for this job', style: AppTextStyles.body2),
            )
          else
            ...tasks.map((t) => _TaskItem(task: t, onToggle: (newStatus) {
                  Provider.of<JobProvider>(context, listen: false).updateTaskStatus(t.id, newStatus);
                })),
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
        children: [
          _buildAssignedParts(job),
        ],
      ),
    );
  }

  Widget _buildNotesTab(Job job) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: NotesWidget(jobId: job.id),
    );
  }

  Widget _buildJobHeader(Job job) {
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
                Expanded(
                  child: Text(
                    job.jobName,
                    style: AppTextStyles.headline1,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: JobStatusHelper.getStatusColor(job.status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Status: ${JobStatusHelper.getStatusText(job.status)}',
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
              style: AppTextStyles.body1,
            ),
            const SizedBox(height: 12),
            if (job.requestedServices.isNotEmpty) ...[
              Text(
                'Requested Services:',
                style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...job.requestedServices.map((service) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(service, style: AppTextStyles.body2),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDetails(Job job) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Details',
              style: AppTextStyles.headline2,
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Name', job.customer.name),
            _buildDetailRow('Contact No', job.customer.contactNo),
            _buildDetailRow('Address', job.customer.address),
            if (job.vehicle != null) ...[
              _buildDetailRow('Plate No', job.vehicle?.plateNo ?? '-'),
              _buildDetailRow(
                'Vehicle',
                [job.vehicle?.brand, job.vehicle?.model, if (job.vehicle?.year != null) job.vehicle!.year.toString()]
                    .where((e) => (e ?? '').toString().isNotEmpty)
                    .join(' ')
                    .trim(),
              ),
            ],
          ],
        ),
      ),
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
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedParts(Job job) {
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
                Text(
                  'Assigned Parts',
                  style: AppTextStyles.headline2,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    _showAddPartDialog();
                  },
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
              ...job.assignedParts.map((part) => _buildPartItem(part)),
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  part.name,
                  style: AppTextStyles.body1.copyWith(fontWeight: FontWeight.w600),
                ),
                if (part.notes != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    part.notes!,
                    style: AppTextStyles.caption,
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Qty: ${part.quantity}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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
              onStart: () {
                setState(() => _isTimerRunning = true);
                Provider.of<JobProvider>(context, listen: false).addTimerEvent(job.id, JobTimerAction.start);
              },
              onPause: () {
                setState(() => _isTimerRunning = false);
                Provider.of<JobProvider>(context, listen: false).addTimerEvent(job.id, JobTimerAction.pause);
              },
              onStop: () {
                setState(() => _isTimerRunning = false);
                Provider.of<JobProvider>(context, listen: false).addTimerEvent(job.id, JobTimerAction.stop);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerLog(Job job) {
    final timers = List<JobTimerEvent>.from((job.timers as List<JobTimerEvent>? ?? const <JobTimerEvent>[]))
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
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
              ...timers.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(_timerIcon(e.action), size: 18, color: _timerColor(e.action)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_actionLabel(e.action), style: AppTextStyles.body1)),
                        Text(DateHelper.formatDateTime(e.timestamp), style: AppTextStyles.caption),
                      ],
                    ),
                  )),
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
  }

  Widget _buildActionButtons(Job job) {
    return Row(
      children: [
        if (job.status == JobStatus.pending) ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateJobStatus(JobStatus.accepted),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Decline'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateJobStatus(JobStatus.accepted),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Accept'),
            ),
          ),
        ] else if (job.status == JobStatus.accepted) ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateJobStatus(JobStatus.inProgress),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Start Job'),
            ),
          ),
        ] else if (job.status == JobStatus.inProgress) ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateJobStatus(JobStatus.onHold),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Put On Hold'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _showCompleteJobDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Complete'),
            ),
          ),
        ] else if (job.status == JobStatus.onHold) ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () => _updateJobStatus(JobStatus.inProgress),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Resume'),
            ),
          ),
        ] else if (job.status == JobStatus.completed) ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () => _showSignatureDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Sign'),
            ),
          ),
        ],
      ],
    );
  }

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

  void _showOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Job Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Job'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Job Details'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('Print Job Details'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Part'),
        content: const Text('Part addition functionality will be implemented here.'),
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
        content: const Text('Are you sure you want to mark this job as completed?'),
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

class _TaskItem extends StatelessWidget {
  final JobTask task;
  final ValueChanged<JobTaskStatus> onToggle;

  const _TaskItem({required this.task, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == JobTaskStatus.completed;
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Checkbox(
              value: isDone,
              onChanged: (v) => onToggle(v == true ? JobTaskStatus.completed : JobTaskStatus.pending),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
            if ((task.tutorialUrl ?? '').isNotEmpty)
              OutlinedButton.icon(
                onPressed: () => Clipboard.setData(ClipboardData(text: task.tutorialUrl!)).then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tutorial link copied')));
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
