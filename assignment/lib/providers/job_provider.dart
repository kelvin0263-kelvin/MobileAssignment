import 'package:flutter/foundation.dart';
import '../models/job.dart';
import '../services/job_service.dart';
import '../services/connectivity_service.dart';
import '../services/offline_queue_service.dart';
import '../services/job_cache_service.dart';

class JobProvider extends ChangeNotifier {
  final JobService _jobService = JobService();
  DateTime? _lastSearchAt;
  Future<void>? _debounceFuture;
  
  List<Job> _jobs = [];
  // Holds the latest results returned from a text search, if any.
  List<Job> _searchResults = [];
  List<Job> _filteredJobs = [];
  Job? _selectedJob;
  bool _isLoading = false;
  String? _error;
  bool _offline = false;
  String _searchQuery = '';
  String _filterStatus = 'all';
  DateTime? _dateFrom;
  DateTime? _dateTo;

  List<Job> get jobs => _jobs;
  List<Job> get filteredJobs => _filteredJobs;
  Job? get selectedJob => _selectedJob;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOffline => _offline;
  String get searchQuery => _searchQuery;
  String get filterStatus => _filterStatus;
  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;

  List<Job> get pendingJobs => _jobs.where((job) => job.status == JobStatus.pending).toList();
  List<Job> get acceptedJobs => _jobs.where((job) => job.status == JobStatus.accepted).toList();
  List<Job> get inProgressJobs => _jobs.where((job) => job.status == JobStatus.inProgress).toList();
  List<Job> get onHoldJobs => _jobs.where((job) => job.status == JobStatus.onHold).toList();
  List<Job> get completedJobs => _jobs.where((job) => job.status == JobStatus.completed).toList();
  List<Job> _vehicleHistory = [];
  List<Job> get vehicleHistory => _vehicleHistory;

  Future<void> loadJobs() async {
    _isLoading = true;
    _error = null;
    _offline = false;
    notifyListeners();

    try {
      final online = ConnectivityService.instance.isOnline;
      if (online) {
        _jobs = await _jobService.getJobs();
        await JobCacheService.instance.saveJobs(_jobs);
      } else {
        _jobs = await JobCacheService.instance.loadJobs();
        _offline = true;
      }
      _applyFilters();
    } catch (e) {
      final cached = await JobCacheService.instance.loadJobs();
      if (cached.isNotEmpty) {
        _jobs = cached;
        _offline = true;
        _applyFilters();
        _error = null;
      } else {
        _error = 'Offline and no cached jobs available';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadJobById(String jobId) async {
    _isLoading = true;
    _error = null;
    _offline = false;
    notifyListeners();

    try {
      final online = ConnectivityService.instance.isOnline;
      if (online) {
        _selectedJob = await _jobService.getJobById(jobId);
        if (_selectedJob != null) {
          await JobCacheService.instance.saveJob(_selectedJob!);
        }
      } else {
        _selectedJob = await JobCacheService.instance.loadJob(jobId);
        // If not found as per-id cache, try within cached list
        if (_selectedJob == null) {
          final cachedList = await JobCacheService.instance.loadJobs();
          for (final j in cachedList) {
            if (j.id == jobId) {
              _selectedJob = j;
              break;
            }
          }
        }
        _offline = true;
      }
      if (_selectedJob == null) {
        _error = 'Job not found';
      }
    } catch (e) {
      _selectedJob = await JobCacheService.instance.loadJob(jobId);
      if (_selectedJob == null) {
        final cachedList = await JobCacheService.instance.loadJobs();
        for (final j in cachedList) {
          if (j.id == jobId) {
            _selectedJob = j;
            break;
          }
        }
      }
      if (_selectedJob != null) {
        _offline = true;
        _error = null;
      } else {
        _error = 'Offline and no cached job available';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadJobsByVehicle(String vehicleId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _vehicleHistory = await _jobService.getJobsByVehicle(vehicleId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateJobStatus(String jobId, JobStatus status) async {
    try {
      final online = ConnectivityService.instance.isOnline;
      if (!online) {
        _applyJobStatusLocally(jobId, status);
        await OfflineQueueService.instance.enqueueUpdateJobStatus(
          jobId: jobId,
          status: _toDbStatus(status),
        );
        return;
      }
      final success = await _jobService.updateJobStatus(jobId, status);
      if (success) {
        _applyJobStatusLocally(jobId, status);
        // Pull fresh from server to reflect authoritative state (and assignment)
        await loadJobById(jobId);
        final idx = _jobs.indexWhere((j) => j.id == jobId);
        if (idx != -1 && _selectedJob != null) {
          _jobs[idx] = _selectedJob!;
          _applyFilters();
        }
      }
    } catch (e) {
      _applyJobStatusLocally(jobId, status);
      await OfflineQueueService.instance.enqueueUpdateJobStatus(
        jobId: jobId,
        status: _toDbStatus(status),
      );
      _error = null;
      notifyListeners();
    }
  }

  void _applyJobStatusLocally(String jobId, JobStatus status) {
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

  Future<void> addJobNote(String jobId, String content, {List<NoteFile> files = const []}) async {
    try {
      final noteId = await _jobService.addJobNote(jobId, content);
      if (noteId != null) {
        if (files.isNotEmpty) {
          await _jobService.attachFilesToNote(noteId, files);
        }
        
        // Optimistically add the note to the UI first for better UX
        if (_selectedJob?.id == jobId) {
          final newNote = JobNote(
            id: noteId,
            content: content,
            createdAt: DateTime.now(),
            files: files,
          );
          
          final updatedNotes = List<JobNote>.from(_selectedJob!.notes)..add(newNote);
          _selectedJob = _selectedJob!.copyWith(notes: updatedNotes);
          
          // Update in jobs list as well
          final jobIndex = _jobs.indexWhere((job) => job.id == jobId);
          if (jobIndex != -1) {
            _jobs[jobIndex] = _jobs[jobIndex].copyWith(notes: updatedNotes);
          }
          
          notifyListeners();
        }
        
        // Then reload in the background to sync with server
        await loadJobById(jobId);
        final jobIndex = _jobs.indexWhere((job) => job.id == jobId);
        if (jobIndex != -1 && _selectedJob != null) {
          _jobs[jobIndex] = _selectedJob!;
        }
        notifyListeners();
      } else {
        throw Exception('Failed to create note');
      }
    } catch (e) {
      _error = 'Failed to add note: ${e.toString()}';
      notifyListeners();
      rethrow; // Re-throw so the UI can handle it
    }
  }

  Future<void> addJobNoteOffline(String jobId, String content, List<String> localImagePaths) async {
    // Build a local note id and files for immediate UI feedback
    final localNoteId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final localFiles = localImagePaths.map((p) => NoteFile(
          id: 'local_${DateTime.now().microsecondsSinceEpoch}',
          noteId: localNoteId,
          fileType: 'photo',
          filePath: p.startsWith('file://') ? p : 'file://$p',
          uploadedAt: null,
        ));

    if (_selectedJob?.id == jobId) {
      final newNote = JobNote(
        id: localNoteId,
        content: content,
        createdAt: DateTime.now(),
        files: localFiles.toList(),
      );
      final updatedNotes = List<JobNote>.from(_selectedJob!.notes)..add(newNote);
      _selectedJob = _selectedJob!.copyWith(notes: updatedNotes);
      final jobIndex = _jobs.indexWhere((job) => job.id == jobId);
      if (jobIndex != -1) {
        _jobs[jobIndex] = _jobs[jobIndex].copyWith(notes: updatedNotes);
      }
      notifyListeners();
    }

    // Queue for sync
    await OfflineQueueService.instance.enqueueAddNote(
      jobId: jobId,
      content: content,
      files: localImagePaths.map((p) => QueuedNoteFile(path: p, fileType: 'photo')).toList(),
    );
  }

  Future<void> updateTaskStatus(String taskId, JobTaskStatus status) async {
    try {
      final online = ConnectivityService.instance.isOnline;
      if (!online) {
        // Optimistic local update + queue
        await _queueTaskStatusUpdate(taskId, status);
        return;
      }
      final success = await _jobService.updateTaskStatus(taskId, status);
      if (success && _selectedJob != null) {
        // Update local selected job tasks
        final updatedTasks = _selectedJob!.tasks.map((t) => t.id == taskId ? t.copyWith(status: status) : t).toList();
        _selectedJob = _selectedJob!.copyWith(tasks: updatedTasks);

        // Also update it within jobs list if present
        final idx = _jobs.indexWhere((j) => j.id == _selectedJob!.id);
        if (idx != -1) {
          _jobs[idx] = _jobs[idx].copyWith(tasks: updatedTasks);
        }
        notifyListeners();
      }
    } catch (e) {
      // If it looks like a network error, queue for later
      await _queueTaskStatusUpdate(taskId, status);
      _error = null;
      notifyListeners();
    }
  }

  Future<void> _queueTaskStatusUpdate(String taskId, JobTaskStatus status) async {
    if (_selectedJob != null) {
      final updatedTasks = _selectedJob!.tasks.map((t) => t.id == taskId ? t.copyWith(status: status) : t).toList();
      _selectedJob = _selectedJob!.copyWith(tasks: updatedTasks);
      final idx = _jobs.indexWhere((j) => j.id == _selectedJob!.id);
      if (idx != -1) {
        _jobs[idx] = _jobs[idx].copyWith(tasks: updatedTasks);
      }
      notifyListeners();
    }
    await OfflineQueueService.instance.enqueueUpdateTaskStatus(
      taskId: taskId,
      status: _toDbTaskStatus(status),
    );
  }

  String _toDbTaskStatus(JobTaskStatus s) {
    switch (s) {
      case JobTaskStatus.pending:
        return 'pending';
      case JobTaskStatus.inProgress:
        return 'in_progress';
      case JobTaskStatus.completed:
        return 'completed';
      case JobTaskStatus.skipped:
        return 'skipped';
    }
  }

  Future<void> addTimerEvent(String jobId, JobTimerAction action, {String? mechanicId}) async {
    try {
      final online = ConnectivityService.instance.isOnline;
      // Optimistic local append
      final evt = JobTimerEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        jobId: jobId,
        action: action,
        timestamp: DateTime.now(),
        mechanicId: mechanicId,
      );
      if (_selectedJob?.id == jobId) {
        final base = (_selectedJob!.timers as List<JobTimerEvent>? ?? const <JobTimerEvent>[]);
        final timers = List<JobTimerEvent>.from(base)..add(evt);
        _selectedJob = _selectedJob!.copyWith(timers: timers);
        final idx = _jobs.indexWhere((j) => j.id == jobId);
        if (idx != -1) {
          _jobs[idx] = _jobs[idx].copyWith(timers: timers);
        }
        notifyListeners();
      }
      if (!online) {
        await OfflineQueueService.instance.enqueueAddTimerEvent(
          jobId: jobId,
          action: _toDbTimerAction(action),
          mechanicId: mechanicId,
        );
        return;
      }
      await _jobService.addTimerEvent(jobId, action, mechanicId: mechanicId);
    } catch (e) {
      await OfflineQueueService.instance.enqueueAddTimerEvent(
        jobId: jobId,
        action: _toDbTimerAction(action),
        mechanicId: mechanicId,
      );
      _error = null;
      notifyListeners();
    }
  }

  String _toDbStatus(JobStatus status) {
    switch (status) {
      case JobStatus.pending:
        return 'pending';
      case JobStatus.accepted:
        return 'accepted';
      case JobStatus.inProgress:
        return 'in_progress';
      case JobStatus.onHold:
        return 'on_hold';
      case JobStatus.completed:
        return 'completed';
      case JobStatus.declined:
        return 'declined';
    }
  }

  String _toDbTimerAction(JobTimerAction a) {
    switch (a) {
      case JobTimerAction.start:
        return 'start';
      case JobTimerAction.pause:
        return 'pause';
      case JobTimerAction.resume:
        return 'resume';
      case JobTimerAction.stop:
        return 'stop';
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
      // Newer search came in; cancel this one
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _searchResults = await _jobService.searchJobs(query);
      _applyActiveFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilterStatus(String status) {
    _filterStatus = status;
    _applyActiveFilters();
    notifyListeners();
  }

  void setDateRange(DateTime? from, DateTime? to) {
    // Normalize to dates (strip time) for predictable inclusive filtering
    _dateFrom = from != null ? DateTime(from.year, from.month, from.day) : null;
    _dateTo = to != null ? DateTime(to.year, to.month, to.day, 23, 59, 59, 999) : null;
    _applyActiveFilters();
    notifyListeners();
  }

  void selectJob(Job job) {
    _selectedJob = job;
    notifyListeners();
  }

  Future<bool> saveJobSignature(String jobId, String signatureUrl) async {
    try {
      final ok = await _jobService.saveJobSignature(jobId, signatureUrl);
      if (ok) {
        if (_selectedJob?.id == jobId) {
          _selectedJob = _selectedJob!.copyWith(digitalSignature: signatureUrl);
        }
        final idx = _jobs.indexWhere((j) => j.id == jobId);
        if (idx != -1) {
          _jobs[idx] = _jobs[idx].copyWith(digitalSignature: signatureUrl);
        }
        notifyListeners();
      }
      return ok;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> saveJobSignatureOffline(String jobId, String localPath) async {
    final path = localPath.startsWith('file://') ? localPath : 'file://$localPath';
    if (_selectedJob?.id == jobId) {
      _selectedJob = _selectedJob!.copyWith(digitalSignature: path);
    }
    final idx = _jobs.indexWhere((j) => j.id == jobId);
    if (idx != -1) {
      _jobs[idx] = _jobs[idx].copyWith(digitalSignature: path);
    }
    notifyListeners();
    await OfflineQueueService.instance.enqueueSaveSignature(jobId: jobId, path: localPath);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _applyFilters() {
    // Called after loading jobs; recompute from base using active filters
    _applyActiveFilters();
  }

  void _applyActiveFilters() {
    // Start from the correct base set: full list when no query,
    // otherwise from the latest search results.
    List<Job> base = _searchQuery.isEmpty ? _jobs : _searchResults;
    var results = List<Job>.from(base);

    // Status filter
    if (_filterStatus != 'all') {
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
        case 'declined':
          status = JobStatus.declined;
          break;
      }
      if (status != null) {
        results = results.where((job) => job.status == status).toList();
      }
    }

    // Date range filter (inclusive) on createdAt
    if (_dateFrom != null || _dateTo != null) {
      results = results.where((job) {
        final dt = job.createdAt;
        final after = _dateFrom == null || !dt.isBefore(_dateFrom!);
        final before = _dateTo == null || !dt.isAfter(_dateTo!);
        return after && before;
      }).toList();
    }

    _filteredJobs = results;
  }
}
