import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/job.dart';

class JobCacheService {
  JobCacheService._internal();
  static final JobCacheService instance = JobCacheService._internal();

  static const String _jobsKey = 'jobs_cache_v1';
  static String _jobKey(String id) => 'job_cache_v1_$id';

  Future<void> saveJobs(List<Job> jobs) async {
    final prefs = await SharedPreferences.getInstance();
    final list = jobs.map(_jobToJson).toList();
    await prefs.setString(_jobsKey, jsonEncode(list));
    // Also save individually for quick detail lookups
    for (final j in jobs) {
      await prefs.setString(_jobKey(j.id), jsonEncode(_jobToJson(j)));
    }
  }

  Future<List<Job>> loadJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_jobsKey);
    if (raw == null || raw.isEmpty) return <Job>[];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => _jobFromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return <Job>[];
    }
  }

  Future<void> saveJob(Job job) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_jobKey(job.id), jsonEncode(_jobToJson(job)));
  }

  Future<Job?> loadJob(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_jobKey(id));
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return _jobFromJson(map);
    } catch (_) {
      // Fallback: try to locate within cached list
      final listRaw = prefs.getString(_jobsKey);
      if (listRaw != null && listRaw.isNotEmpty) {
        try {
          final list = jsonDecode(listRaw) as List<dynamic>;
          for (final e in list) {
            final m = Map<String, dynamic>.from(e as Map);
            if ((m['id'] ?? '') == id) {
              return _jobFromJson(m);
            }
          }
        } catch (_) {}
      }
      return null;
    }
  }

  // ---- Serialization helpers ----

  Map<String, dynamic> _jobToJson(Job j) => {
        'id': j.id,
        'jobName': j.jobName,
        'description': j.description,
        'status': _statusToStr(j.status),
        'createdAt': j.createdAt.toIso8601String(),
        'startTime': j.startTime?.toIso8601String(),
        'endTime': j.endTime?.toIso8601String(),
        'estimatedDuration': j.estimatedDuration,
        'actualDuration': j.actualDuration,
        'assignedMechanicId': j.assignedMechanicId,
        'priority': j.priority,
        'customer': _customerToJson(j.customer),
        'vehicle': j.vehicle != null ? _vehicleToJson(j.vehicle!) : null,
        'requestedServices': j.requestedServices,
        'assignedParts': j.assignedParts.map(_assignedPartToJson).toList(),
        'notes': j.notes.map(_jobNoteToJson).toList(),
        'deadline': j.deadline?.toIso8601String(),
        'digitalSignature': j.digitalSignature,
        'tasks': j.tasks.map(_taskToJson).toList(),
        'timers': j.timers.map(_timerToJson).toList(),
      };

  Job _jobFromJson(Map<String, dynamic> m) => Job(
        id: m['id'] as String,
        jobName: m['jobName'] as String? ?? m['job_name'] as String? ?? '',
        description: m['description'] as String? ?? '',
        status: _parseStatus(m['status'] as String? ?? 'pending'),
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
        startTime: (m['startTime'] as String?) != null ? DateTime.tryParse(m['startTime'] as String) : null,
        endTime: (m['endTime'] as String?) != null ? DateTime.tryParse(m['endTime'] as String) : null,
        estimatedDuration: m['estimatedDuration'] as int?,
        actualDuration: m['actualDuration'] as int?,
        assignedMechanicId: m['assignedMechanicId'] as String?,
        priority: m['priority'] as String?,
        customer: _customerFromJson(Map<String, dynamic>.from(m['customer'] as Map)),
        vehicle: m['vehicle'] != null ? _vehicleFromJson(Map<String, dynamic>.from(m['vehicle'] as Map)) : null,
        requestedServices: List<String>.from(m['requestedServices'] as List? ?? const []),
        assignedParts: (m['assignedParts'] as List? ?? const [])
            .map((e) => _assignedPartFromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        notes: (m['notes'] as List? ?? const [])
            .map((e) => _jobNoteFromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        deadline: (m['deadline'] as String?) != null ? DateTime.tryParse(m['deadline'] as String) : null,
        digitalSignature: m['digitalSignature'] as String?,
        tasks: (m['tasks'] as List? ?? const [])
            .map((e) => _taskFromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        timers: (m['timers'] as List? ?? const [])
            .map((e) => _timerFromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  Map<String, dynamic> _customerToJson(Customer c) => {
        'name': c.name,
        'contactNo': c.contactNo,
        'address': c.address,
      };
  Customer _customerFromJson(Map<String, dynamic> m) => Customer(
        name: m['name'] as String? ?? '',
        contactNo: m['contactNo'] as String? ?? '',
        address: m['address'] as String? ?? '',
      );

  Map<String, dynamic> _vehicleToJson(Vehicle v) => {
        'id': v.id,
        'brand': v.brand,
        'model': v.model,
        'year': v.year,
        'plateNo': v.plateNo,
      };
  Vehicle _vehicleFromJson(Map<String, dynamic> m) => Vehicle(
        id: m['id'] as String? ?? '',
        brand: m['brand'] as String?,
        model: m['model'] as String?,
        year: (m['year'] is int) ? m['year'] as int : int.tryParse((m['year'] ?? '').toString()),
        plateNo: m['plateNo'] as String?,
      );

  Map<String, dynamic> _assignedPartToJson(AssignedPart p) => {
        'name': p.name,
        'quantity': p.quantity,
        'notes': p.notes,
      };
  AssignedPart _assignedPartFromJson(Map<String, dynamic> m) => AssignedPart(
        name: m['name'] as String? ?? '',
        quantity: (m['quantity'] is int) ? m['quantity'] as int : int.tryParse((m['quantity'] ?? '0').toString()) ?? 0,
        notes: m['notes'] as String?,
      );

  Map<String, dynamic> _jobNoteToJson(JobNote n) => {
        'id': n.id,
        'content': n.content,
        'createdAt': n.createdAt.toIso8601String(),
        'imagePath': n.imagePath,
        'files': n.files.map(_noteFileToJson).toList(),
      };
  JobNote _jobNoteFromJson(Map<String, dynamic> m) => JobNote(
        id: m['id'] as String? ?? '',
        content: m['content'] as String? ?? '',
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
        imagePath: m['imagePath'] as String?,
        files: (m['files'] as List? ?? const [])
            .map((e) => _noteFileFromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  Map<String, dynamic> _noteFileToJson(NoteFile f) => {
        'id': f.id,
        'noteId': f.noteId,
        'fileType': f.fileType,
        'filePath': f.filePath,
        'uploadedAt': f.uploadedAt?.toIso8601String(),
      };
  NoteFile _noteFileFromJson(Map<String, dynamic> m) => NoteFile(
        id: m['id'] as String? ?? '',
        noteId: m['noteId'] as String? ?? '',
        fileType: m['fileType'] as String? ?? 'photo',
        filePath: m['filePath'] as String? ?? '',
        uploadedAt: (m['uploadedAt'] as String?) != null ? DateTime.tryParse(m['uploadedAt'] as String) : null,
      );

  Map<String, dynamic> _taskToJson(JobTask t) => {
        'id': t.id,
        'description': t.description,
        'status': _taskStatusToStr(t.status),
        'assignedMechanicId': t.assignedMechanicId,
        'tutorialUrl': t.tutorialUrl,
        'startTime': t.startTime?.toIso8601String(),
        'endTime': t.endTime?.toIso8601String(),
        'procedureId': t.procedureId,
        'procedureStepId': t.procedureStepId,
        'stepNumber': t.stepNumber,
      };
  JobTask _taskFromJson(Map<String, dynamic> m) => JobTask(
        id: m['id'] as String? ?? '',
        description: m['description'] as String? ?? '',
        status: _parseTaskStatus(m['status'] as String? ?? 'pending'),
        assignedMechanicId: m['assignedMechanicId'] as String?,
        tutorialUrl: m['tutorialUrl'] as String?,
        startTime: (m['startTime'] as String?) != null ? DateTime.tryParse(m['startTime'] as String) : null,
        endTime: (m['endTime'] as String?) != null ? DateTime.tryParse(m['endTime'] as String) : null,
        procedureId: m['procedureId'] as String?,
        procedureStepId: m['procedureStepId'] as String?,
        stepNumber: (m['stepNumber'] is int)
            ? m['stepNumber'] as int
            : int.tryParse((m['stepNumber'] ?? '').toString()),
      );

  Map<String, dynamic> _timerToJson(JobTimerEvent e) => {
        'id': e.id,
        'jobId': e.jobId,
        'action': _timerActionToStr(e.action),
        'timestamp': e.timestamp.toIso8601String(),
        'mechanicId': e.mechanicId,
      };
  JobTimerEvent _timerFromJson(Map<String, dynamic> m) => JobTimerEvent(
        id: m['id'] as String? ?? '',
        jobId: m['jobId'] as String? ?? '',
        action: _parseTimerAction(m['action'] as String? ?? 'stop'),
        timestamp: DateTime.tryParse(m['timestamp'] as String? ?? '') ?? DateTime.now(),
        mechanicId: m['mechanicId'] as String?,
      );

  // ---- Enum helpers ----
  String _statusToStr(JobStatus s) {
    switch (s) {
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

  JobStatus _parseStatus(String s) {
    switch (s) {
      case 'accepted':
        return JobStatus.accepted;
      case 'in_progress':
        return JobStatus.inProgress;
      case 'on_hold':
        return JobStatus.onHold;
      case 'completed':
        return JobStatus.completed;
      case 'declined':
        return JobStatus.declined;
      case 'pending':
      default:
        return JobStatus.pending;
    }
  }

  String _taskStatusToStr(JobTaskStatus s) {
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

  JobTaskStatus _parseTaskStatus(String s) {
    switch (s) {
      case 'in_progress':
        return JobTaskStatus.inProgress;
      case 'completed':
        return JobTaskStatus.completed;
      case 'skipped':
        return JobTaskStatus.skipped;
      case 'pending':
      default:
        return JobTaskStatus.pending;
    }
  }

  String _timerActionToStr(JobTimerAction a) {
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

  JobTimerAction _parseTimerAction(String s) {
    switch (s) {
      case 'start':
        return JobTimerAction.start;
      case 'pause':
        return JobTimerAction.pause;
      case 'resume':
        return JobTimerAction.resume;
      case 'stop':
      default:
        return JobTimerAction.stop;
    }
  }
}
