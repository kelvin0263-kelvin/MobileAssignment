import 'package:flutter/foundation.dart';
import '../models/job.dart';
import '../services/job_service.dart';

class JobProvider extends ChangeNotifier {
  final JobService _jobService = JobService();
  DateTime? _lastSearchAt;
  Future<void>? _debounceFuture;
  
  List<Job> _jobs = [];
  List<Job> _filteredJobs = [];
  Job? _selectedJob;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _filterStatus = 'all';

  List<Job> get jobs => _jobs;
  List<Job> get filteredJobs => _filteredJobs;
  Job? get selectedJob => _selectedJob;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get filterStatus => _filterStatus;

  List<Job> get pendingJobs => _jobs.where((job) => job.status == JobStatus.pending).toList();
  List<Job> get acceptedJobs => _jobs.where((job) => job.status == JobStatus.accepted).toList();
  List<Job> get inProgressJobs => _jobs.where((job) => job.status == JobStatus.inProgress).toList();
  List<Job> get onHoldJobs => _jobs.where((job) => job.status == JobStatus.onHold).toList();
  List<Job> get completedJobs => _jobs.where((job) => job.status == JobStatus.completed).toList();

  Future<void> loadJobs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _jobs = await _jobService.getJobs();
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadJobById(String jobId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedJob = await _jobService.getJobById(jobId);
      if (_selectedJob == null) {
        _error = 'Job not found';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateJobStatus(String jobId, JobStatus status) async {
    try {
      final success = await _jobService.updateJobStatus(jobId, status);
      if (success) {
        // Update the job in the list
        final jobIndex = _jobs.indexWhere((job) => job.id == jobId);
        if (jobIndex != -1) {
          _jobs[jobIndex] = _jobs[jobIndex].copyWith(status: status);
        }
        
        // Update selected job if it's the same
        if (_selectedJob?.id == jobId) {
          _selectedJob = _selectedJob!.copyWith(status: status);
        }
        
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addJobNote(String jobId, String content, String? imagePath) async {
    try {
      final success = await _jobService.addJobNote(jobId, content, imagePath);
      if (success) {
        // Reload the job to get updated notes
        await loadJobById(jobId);
        
        // Update the job in the list
        final jobIndex = _jobs.indexWhere((job) => job.id == jobId);
        if (jobIndex != -1) {
          _jobs[jobIndex] = _selectedJob!;
        }
        
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> searchJobs(String query) async {
    _searchQuery = query;
    final now = DateTime.now();
    _lastSearchAt = now;

    // Debounce: wait 300ms; if no newer search scheduled, execute
    _isLoading = true;
    notifyListeners();

    _debounceFuture = Future.delayed(const Duration(milliseconds: 300));
    await _debounceFuture;
    if (_lastSearchAt != now) {
      return; // Newer search came in; cancel this one
    }

    try {
      _filteredJobs = await _jobService.searchJobs(query);
      _applyStatusFilter();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilterStatus(String status) {
    _filterStatus = status;
    _applyStatusFilter();
    notifyListeners();
  }

  void selectJob(Job job) {
    _selectedJob = job;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _applyFilters() {
    _filteredJobs = List.from(_jobs);
    _applyStatusFilter();
  }

  void _applyStatusFilter() {
    if (_filterStatus == 'all') {
      return; // Keep all jobs
    }

    JobStatus? status;
    switch (_filterStatus) {
      case 'pending':
        status = JobStatus.pending;
        break;
      case 'inProgress':
        status = JobStatus.inProgress;
        break;
      case 'onHold':
        status = JobStatus.onHold;
        break;
      case 'completed':
        status = JobStatus.completed;
        break;
    }

    if (status != null) {
      _filteredJobs = _filteredJobs.where((job) => job.status == status).toList();
    }
  }
}
