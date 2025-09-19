import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/job.dart';

class JobService {
  final SupabaseClient _client = Supabase.instance.client;
  int? _cachedEmployeeId; // Session-scoped cache
  String? _cachedForAuthUserId;

  // Resolves the current employee.id for the logged-in auth user
  Future<int?> _getCurrentEmployeeId() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;
      // Reset cache if auth user changed
      if (_cachedForAuthUserId != user.id) {
        _cachedEmployeeId = null;
        _cachedForAuthUserId = user.id;
      }
      if (_cachedEmployeeId != null) return _cachedEmployeeId;
      final row = await _client
          .from('employees')
          .select('id')
          .eq('auth_user_id', user.id)
          .maybeSingle();
      if (row == null) {
        // Attempt to create employee record for existing auth users
        try {
          final insert = await _client
              .from('employees')
              .insert({
                'auth_user_id': user.id,
                'name': (user.userMetadata?['name'] as String?) ?? (user.email?.split('@').first ?? 'User'),
                'role': 'mechanic',
                'email': user.email ?? 'unknown@example.com',
              })
              .select('id')
              .maybeSingle();
          if (insert != null) {
            final id = (insert['id'] as num).toInt();
            _cachedEmployeeId = id;
            return id;
          }
        } catch (_) {
          // ignore and fall through to null
        }
        return null;
      } else {
        final id = (row['id'] as num).toInt();
        _cachedEmployeeId = id;
        return id;
      }
    } catch (_) {
      return null;
    }
  }

  // --- Mapping helpers ---
  JobStatus _parseStatus(String s) {
    switch (s) {
      case 'pending':
        return JobStatus.pending;
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
      default:
        return JobStatus.pending;
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

  // --- Public API ---
  Future<List<Job>> getJobs() async {
    final myEmpId = await _getCurrentEmployeeId();
    final sel = 'id, job_name, description, status, priority, customer_id, vehicle_id, assigned_mechanic_id, created_at, start_time, end_time, estimated_duration, actual_duration, deadline, digital_signature';
    List rows;
    if (myEmpId == null) {
      rows = await _client
          .from('jobs')
          .select(sel)
          .eq('status', 'pending')
          .filter('assigned_mechanic_id', 'is', null)
          .order('created_at', ascending: false);
    } else {
      final pendingUnassigned = await _client
          .from('jobs')
          .select(sel)
          .eq('status', 'pending')
          .filter('assigned_mechanic_id', 'is', null)
          .order('created_at', ascending: false);
      final assignedToMe = await _client
          .from('jobs')
          .select(sel)
          .eq('assigned_mechanic_id', myEmpId)
          .order('created_at', ascending: false);
      final mapRows = <String, Map<String, dynamic>>{};
      for (final r in List<Map<String, dynamic>>.from(pendingUnassigned)) {
        mapRows[r['id'].toString()] = r;
      }
      for (final r in List<Map<String, dynamic>>.from(assignedToMe)) {
        mapRows[r['id'].toString()] = r;
      }
      rows = mapRows.values.toList()
        ..sort((a, b) => DateTime.parse(b['created_at'] as String)
            .compareTo(DateTime.parse(a['created_at'] as String)));
    }

    return _hydrateJobs(List<Map<String, dynamic>>.from(rows));
  }

  Future<List<Job>> getJobsByVehicle(String vehicleId) async {
    final myEmpId = await _getCurrentEmployeeId();
    final sel = 'id, job_name, description, status, priority, customer_id, vehicle_id, assigned_mechanic_id, created_at, start_time, end_time, estimated_duration, actual_duration, deadline, digital_signature';
    List rows;
    if (myEmpId == null) {
      rows = await _client
          .from('jobs')
          .select(sel)
          .eq('vehicle_id', vehicleId)
          .eq('status', 'pending')
          .filter('assigned_mechanic_id', 'is', null)
          .order('start_time', ascending: false);
    } else {
      final pendingUnassigned = await _client
          .from('jobs')
          .select(sel)
          .eq('vehicle_id', vehicleId)
          .eq('status', 'pending')
          .filter('assigned_mechanic_id', 'is', null)
          .order('start_time', ascending: false);
      final assignedToMe = await _client
          .from('jobs')
          .select(sel)
          .eq('vehicle_id', vehicleId)
          .eq('assigned_mechanic_id', myEmpId)
          .order('start_time', ascending: false);
      final mapRows = <String, Map<String, dynamic>>{};
      for (final r in List<Map<String, dynamic>>.from(pendingUnassigned)) {
        mapRows[r['id'].toString()] = r;
      }
      for (final r in List<Map<String, dynamic>>.from(assignedToMe)) {
        mapRows[r['id'].toString()] = r;
      }
      rows = mapRows.values.toList()
        ..sort((a, b) => (b['start_time'] ?? '').toString().compareTo((a['start_time'] ?? '').toString()));
    }

    return _hydrateJobs(List<Map<String, dynamic>>.from(rows));
  }

  Future<Job?> getJobById(String jobId) async {
    final myEmpId = await _getCurrentEmployeeId();
    final rows = await _client
        .from('jobs')
        .select('id, job_name, description, status, priority, customer_id, vehicle_id, assigned_mechanic_id, created_at, start_time, end_time, estimated_duration, actual_duration, deadline, digital_signature')
        .eq('id', jobId)
        .limit(1);
    if (rows.isEmpty) return null;
    // Enforce access: allow if pending+unassigned or assigned to me
    final r = Map<String, dynamic>.from(List.from(rows).first as Map);
    final assigned = r['assigned_mechanic_id'];
    final status = (r['status'] ?? '').toString();
    final canView = (assigned == null && status == 'pending') || (myEmpId != null && assigned == myEmpId);
    if (!canView) return null;
    final list = await _hydrateJobs([r]);
    return list.isNotEmpty ? list.first : null;
  }

  Future<bool> updateJobStatus(String jobId, JobStatus status) async {
    try {
      final data = <String, dynamic>{'status': _toDbStatus(status)};
      if (status == JobStatus.accepted) {
        final empId = await _getCurrentEmployeeId();
        if (empId != null) {
          data['assigned_mechanic_id'] = empId;
        }
      }
      await _client
          .from('jobs')
          .update(data)
          .eq('id', jobId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> addJobNote(String jobId, String content) async {
    try {
      final res = await _client
          .from('job_notes')
          .insert({
            'job_id': jobId, 
            'content': content,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .maybeSingle();
      return res?['id']?.toString();
    } catch (e) {
      print('Error adding job note: $e');
      // If it's a duplicate key error, try to get the existing note
      if (e.toString().contains('duplicate key') || e.toString().contains('already exists')) {
        // Generate a unique ID by adding timestamp
        final uniqueId = 'note_${DateTime.now().millisecondsSinceEpoch}';
        final res = await _client
            .from('job_notes')
            .insert({
              'id': uniqueId,
              'job_id': jobId, 
              'content': content,
              'created_at': DateTime.now().toIso8601String(),
            })
            .select('id')
            .maybeSingle();
        return res?['id']?.toString();
      }
      rethrow;
    }
  }

  Future<void> attachFilesToNote(String noteId, List<NoteFile> files) async {
    if (files.isEmpty) return;
    final payload = files
        .map((f) => {
              'note_id': noteId,
              'file_type': f.fileType,
              'file_path': f.filePath,
            })
        .toList();
    await _client.from('job_note_files').insert(payload);
  }

  Future<bool> updateTaskStatus(String taskId, JobTaskStatus status) async {
    final res = await _client
        .from('job_tasks')
        .update({'status': _toDbTaskStatus(status)})
        .eq('id', taskId)
        .select('id')
        .maybeSingle();
    return res != null;
  }

  Future<bool> addTimerEvent(String jobId, JobTimerAction action, {String? mechanicId}) async {
    int? mechId;
    if (mechanicId != null) {
      mechId = int.tryParse(mechanicId);
    }
    mechId ??= await _getCurrentEmployeeId();
    final res = await _client
        .from('job_timers')
        .insert({
          'job_id': jobId,
          'mechanic_id': mechId,
          'action': _toDbTimerAction(action),
        })
        .select('id')
        .maybeSingle();
    return res != null;
  }

  Future<bool> saveJobSignature(String jobId, String signatureUrl) async {
    final res = await _client
        .from('jobs')
        .update({'digital_signature': signatureUrl})
        .eq('id', jobId)
        .select('id')
        .maybeSingle();
    return res != null;
  }

  Future<List<Job>> searchJobs(String query) async {
    // Fetch visible jobs and then filter client-side for simplicity with complex visibility constraints
    final all = await getJobs();
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return all;
    return all.where((j) {
      final hay = '${j.jobName} ${j.description} ${j.customer.name} ${j.vehicle?.plateNo ?? ''}'.toLowerCase();
      return hay.contains(term);
    }).toList();
  }

  // --- Hydration helpers ---
  Future<List<Job>> _hydrateJobs(List<Map<String, dynamic>> jobRows) async {
    if (jobRows.isEmpty) return [];
    final jobIds = jobRows.map((r) => r['id'].toString()).toList();
    final customerIds = jobRows
        .map((r) => r['customer_id'])
        .where((id) => id != null)
        .map((id) => id.toString())
        .toSet()
        .toList();
    final vehicleIds = jobRows
        .map((r) => r['vehicle_id'])
        .where((id) => id != null)
        .map((id) => id.toString())
        .toSet()
        .toList();

    // Customers
    final customers = customerIds.isEmpty
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(await _client
            .from('customers')
            .select('id, name, contact_no, address')
            .inFilter('id', customerIds));
    final customersById = {
      for (final c in customers) c['id'].toString(): c,
    };

    // Vehicles
    final vehicles = vehicleIds.isEmpty
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(await _client
            .from('vehicles')
            .select('id, customer_id, brand, model, year, plate_no')
            .inFilter('id', vehicleIds));
    final vehiclesById = { for (final v in vehicles) v['id'].toString(): v };

    // Requested services
    final services = List<Map<String, dynamic>>.from(await _client
        .from('job_services')
        .select('job_id, service_name')
        .inFilter('job_id', jobIds));
    final servicesByJob = <String, List<String>>{};
    for (final s in services) {
      final id = s['job_id'].toString();
      (servicesByJob[id] ??= <String>[]).add((s['service_name'] ?? '').toString());
    }

    // Assigned parts
    final parts = List<Map<String, dynamic>>.from(await _client
        .from('assigned_parts')
        .select('job_id, name, quantity, notes')
        .inFilter('job_id', jobIds));
    final partsByJob = <String, List<AssignedPart>>{};
    for (final p in parts) {
      final id = p['job_id'].toString();
      (partsByJob[id] ??= <AssignedPart>[]).add(AssignedPart(
        name: (p['name'] ?? '').toString(),
        quantity: (p['quantity'] ?? 1) as int,
        notes: p['notes'] as String?,
      ));
    }

    // Notes
    final notes = List<Map<String, dynamic>>.from(await _client
        .from('job_notes')
        .select('id, job_id, content, created_at')
        .inFilter('job_id', jobIds)
        .order('created_at'));
    final noteIds = notes.map((n) => n['id'].toString()).toList();
    final noteFiles = noteIds.isEmpty
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(await _client
            .from('job_note_files')
            .select('id, note_id, file_type, file_path, uploaded_at')
            .inFilter('note_id', noteIds));
    final filesByNote = <String, List<NoteFile>>{};
    for (final f in noteFiles) {
      final nId = f['note_id'].toString();
      (filesByNote[nId] ??= <NoteFile>[]).add(NoteFile(
        id: f['id'].toString(),
        noteId: nId,
        fileType: (f['file_type'] ?? '').toString(),
        filePath: (f['file_path'] ?? '').toString(),
        uploadedAt: f['uploaded_at'] != null ? DateTime.parse(f['uploaded_at'] as String) : null,
      ));
    }
    final notesByJob = <String, List<JobNote>>{};
    for (final n in notes) {
      final jobIdStr = n['job_id'].toString();
      final nId = n['id'].toString();
      (notesByJob[jobIdStr] ??= <JobNote>[]).add(JobNote(
        id: nId,
        content: (n['content'] ?? '').toString(),
        createdAt: DateTime.parse(n['created_at'] as String),
        files: filesByNote[nId] ?? const <NoteFile>[],
      ));
    }

    // Job tasks
    final tasks = List<Map<String, dynamic>>.from(await _client
        .from('job_tasks')
        .select('id, job_id, description, status, assigned_mechanic_id, tutorial_url, start_time, end_time, procedure_id, procedure_step_id')
        .inFilter('job_id', jobIds));
    final tasksByJob = <String, List<JobTask>>{};
    for (final t in tasks) {
      final id = t['job_id'].toString();
      (tasksByJob[id] ??= <JobTask>[]).add(JobTask(
        id: t['id'].toString(),
        description: (t['description'] ?? '').toString(),
        status: _parseTaskStatus((t['status'] ?? 'pending') as String),
        assignedMechanicId: t['assigned_mechanic_id']?.toString(),
        tutorialUrl: t['tutorial_url'] as String?,
        startTime: t['start_time'] != null ? DateTime.parse(t['start_time'] as String) : null,
        endTime: t['end_time'] != null ? DateTime.parse(t['end_time'] as String) : null,
        procedureId: t['procedure_id']?.toString(),
        procedureStepId: t['procedure_step_id']?.toString(),
        stepNumber: null,
      ));
    }

    // Timer logs
    final timers = List<Map<String, dynamic>>.from(await _client
        .from('job_timers')
        .select('id, job_id, mechanic_id, action, timestamp')
        .inFilter('job_id', jobIds)
        .order('timestamp'));
    final timersByJob = <String, List<JobTimerEvent>>{};
    for (final t in timers) {
      final id = t['job_id'].toString();
      (timersByJob[id] ??= <JobTimerEvent>[]).add(JobTimerEvent(
        id: t['id'].toString(),
        jobId: id,
        action: _parseTimerAction((t['action'] ?? 'stop') as String),
        timestamp: DateTime.parse(t['timestamp'] as String),
        mechanicId: t['mechanic_id']?.toString(),
      ));
    }

    // Build final Job objects
    final jobs = <Job>[];
    for (final r in jobRows) {
      final customerRow = customersById[r['customer_id']?.toString()];
      final customer = Customer(
        name: (customerRow?['name'] ?? 'Unknown') as String,
        contactNo: (customerRow?['contact_no'] ?? '') as String,
        address: (customerRow?['address'] ?? '') as String,
      );
      final vehicleRow = vehiclesById[r['vehicle_id']?.toString()];
      final vehicle = vehicleRow == null
          ? null
          : Vehicle(
              id: vehicleRow['id'].toString(),
              brand: vehicleRow['brand'] as String?,
              model: vehicleRow['model'] as String?,
              year: vehicleRow['year'] as int?,
              plateNo: vehicleRow['plate_no'] as String?,
            );

      jobs.add(Job(
        id: r['id'].toString(),
        jobName: (r['job_name'] ?? '') as String,
        description: (r['description'] ?? '') as String,
        status: _parseStatus((r['status'] ?? 'pending') as String),
        createdAt: DateTime.parse(r['created_at'] as String),
        startTime: r['start_time'] != null ? DateTime.parse(r['start_time'] as String) : null,
        endTime: r['end_time'] != null ? DateTime.parse(r['end_time'] as String) : null,
        estimatedDuration: r['estimated_duration'] as int?,
        actualDuration: r['actual_duration'] as int?,
        assignedMechanicId: r['assigned_mechanic_id']?.toString(),
        priority: (r['priority'] ?? 'medium') as String?,
        deadline: r['deadline'] != null ? DateTime.parse(r['deadline'] as String) : null,
        digitalSignature: r['digital_signature'] as String?,
        customer: customer,
        vehicle: vehicle,
        requestedServices: servicesByJob[r['id'].toString()] ?? const <String>[],
        assignedParts: partsByJob[r['id'].toString()] ?? const <AssignedPart>[],
        notes: notesByJob[r['id'].toString()] ?? const <JobNote>[],
        tasks: tasksByJob[r['id'].toString()] ?? const <JobTask>[],
        timers: timersByJob[r['id'].toString()] ?? const <JobTimerEvent>[],
      ));
    }
    return jobs;
  }
}
