import 'dart:async';
import 'dart:io';

import '../models/job.dart';
import 'connectivity_service.dart';
import 'offline_queue_service.dart';
import 'supabase_storage_service.dart';
import 'job_service.dart';

class SyncService {
  SyncService._internal();
  static final SyncService instance = SyncService._internal();

  final ConnectivityService _connectivity = ConnectivityService.instance;
  final OfflineQueueService _queue = OfflineQueueService.instance;
  final SupabaseStorageService _storage = SupabaseStorageService();
  final JobService _jobs = JobService();

  StreamSubscription<bool>? _sub;
  bool _running = false;
  final StreamController<bool> _syncingController = StreamController<bool>.broadcast();

  bool get isSyncing => _running;
  Stream<bool> get onSyncing => _syncingController.stream;

  Future<void> init() async {
    await _queue.init();
    await _connectivity.init();
    _sub?.cancel();
    _sub = _connectivity.onStatusChange.listen((online) {
      if (online) {
        _sync();
      }
    });

    if (_connectivity.isOnline) {
      _sync();
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _syncingController.close();
  }

  Future<void> _sync() async {
    if (_running) return;
    _running = true;
    _syncingController.add(true);
    try {
      // Copy to avoid concurrent modification
      final actions = List<OfflineAction>.from(_queue.queue);
      for (final action in actions) {
        try {
          switch (action.type) {
            case OfflineActionType.addNote:
              await _handleAddNote(action);
              break;
            case OfflineActionType.updateTaskStatus:
              await _handleUpdateTaskStatus(action);
              break;
            case OfflineActionType.updateJobStatus:
              await _handleUpdateJobStatus(action);
              break;
            case OfflineActionType.addTimerEvent:
              await _handleAddTimerEvent(action);
              break;
            case OfflineActionType.saveSignature:
              await _handleSaveSignature(action);
              break;
          }
          await _queue.remove(action.id);
          // Small delay to ensure backend write visibility for subsequent fetches
          await Future.delayed(const Duration(milliseconds: 150));
        } catch (_) {
          // Stop on first failure to retry later
          break;
        }
      }
    } finally {
      _running = false;
      _syncingController.add(false);
    }
  }

  Future<void> _handleAddNote(OfflineAction action) async {
    final jobId = action.payload['jobId'] as String;
    final content = action.payload['content'] as String;
    final filesJson = List<Map<String, dynamic>>.from(action.payload['files'] as List? ?? const []);
    final localFiles = filesJson.map(QueuedNoteFile.fromJson).toList();

    final noteId = await _jobs.addJobNote(jobId, content);
    if (noteId == null) throw Exception('Failed to create remote note');

    if (localFiles.isEmpty) return;

    final uploaded = <NoteFile>[];
    for (int i = 0; i < localFiles.length; i++) {
      final f = localFiles[i];
      try {
        final file = File(f.path);
        if (!await file.exists()) continue;
        final bytes = await file.readAsBytes();
        final filename = 'img_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final url = await _storage.uploadNoteImage(bytes, filename: filename);
        uploaded.add(NoteFile(
          id: 'up_$i',
          noteId: noteId,
          fileType: f.fileType,
          filePath: url,
          uploadedAt: DateTime.now(),
        ));
        // Cleanup local file after successful upload
        try {
          await file.delete();
        } catch (_) {}
      } catch (_) {
        // continue with other files
      }
    }

    if (uploaded.isNotEmpty) {
      await _jobs.attachFilesToNote(noteId, uploaded);
    }
  }

  Future<void> _handleUpdateTaskStatus(OfflineAction action) async {
    final taskId = action.payload['taskId'] as String;
    final s = (action.payload['status'] as String).toLowerCase();
    final status = _parseTaskStatus(s);
    await _jobs.updateTaskStatus(taskId, status);
  }

  Future<void> _handleUpdateJobStatus(OfflineAction action) async {
    final jobId = action.payload['jobId'] as String;
    final s = (action.payload['status'] as String).toLowerCase();
    final status = _parseJobStatus(s);
    await _jobs.updateJobStatus(jobId, status);
  }

  Future<void> _handleAddTimerEvent(OfflineAction action) async {
    final jobId = action.payload['jobId'] as String;
    final a = (action.payload['action'] as String).toLowerCase();
    final mechanicId = action.payload['mechanicId'] as String?;
    final evt = _parseTimerAction(a);
    await _jobs.addTimerEvent(jobId, evt, mechanicId: mechanicId);
  }

  Future<void> _handleSaveSignature(OfflineAction action) async {
    final jobId = action.payload['jobId'] as String;
    final path = action.payload['path'] as String;
    final file = File(path);
    if (!await file.exists()) throw Exception('Signature file missing');
    final bytes = await file.readAsBytes();
    final url = await _storage.uploadSignature(bytes, jobId: jobId);
    final ok = await _jobs.saveJobSignature(jobId, url);
    if (ok) {
      try {
        await file.delete();
      } catch (_) {}
    } else {
      throw Exception('Failed to save signature');
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

  JobStatus _parseJobStatus(String s) {
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
}
