import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class QueuedNoteFile {
  final String path; // absolute local path
  final String fileType; // e.g. 'photo'

  QueuedNoteFile({required this.path, required this.fileType});

  Map<String, dynamic> toJson() => {
        'path': path,
        'fileType': fileType,
      };

  static QueuedNoteFile fromJson(Map<String, dynamic> json) =>
      QueuedNoteFile(path: json['path'] as String, fileType: json['fileType'] as String);
}

enum OfflineActionType { addNote, updateTaskStatus, updateJobStatus, addTimerEvent, saveSignature }

class OfflineAction {
  final String id; // unique id
  final OfflineActionType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  OfflineAction({required this.id, required this.type, required this.payload, required this.createdAt});

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
      };

  static OfflineAction fromJson(Map<String, dynamic> json) => OfflineAction(
        id: json['id'] as String,
        type: OfflineActionType.values.firstWhere((e) => e.name == json['type'] as String),
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class OfflineQueueService {
  OfflineQueueService._internal();
  static final OfflineQueueService instance = OfflineQueueService._internal();

  static const _prefsKey = 'offline_queue_v1';
  final List<OfflineAction> _queue = <OfflineAction>[];
  bool _initialized = false;

  List<OfflineAction> get queue => List.unmodifiable(_queue);

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _queue
          ..clear()
          ..addAll(list.map((e) => OfflineAction.fromJson(Map<String, dynamic>.from(e as Map))));
      } catch (_) {}
    }
    _initialized = true;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_queue.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKey, raw);
  }

  String _uid() => DateTime.now().millisecondsSinceEpoch.toString();

  Future<void> enqueueAddNote({
    required String jobId,
    required String content,
    required List<QueuedNoteFile> files,
  }) async {
    await init();
    final action = OfflineAction(
      id: _uid(),
      type: OfflineActionType.addNote,
      payload: {
        'jobId': jobId,
        'content': content,
        'files': files.map((f) => f.toJson()).toList(),
      },
      createdAt: DateTime.now(),
    );
    _queue.add(action);
    await _persist();
  }

  Future<void> enqueueUpdateTaskStatus({
    required String taskId,
    required String status, // pending | in_progress | completed | skipped
  }) async {
    await init();
    final action = OfflineAction(
      id: _uid(),
      type: OfflineActionType.updateTaskStatus,
      payload: {
        'taskId': taskId,
        'status': status,
      },
      createdAt: DateTime.now(),
    );
    _queue.add(action);
    await _persist();
  }

  Future<void> enqueueUpdateJobStatus({
    required String jobId,
    required String status, // pending | accepted | in_progress | on_hold | completed
  }) async {
    await init();
    final action = OfflineAction(
      id: _uid(),
      type: OfflineActionType.updateJobStatus,
      payload: {
        'jobId': jobId,
        'status': status,
      },
      createdAt: DateTime.now(),
    );
    _queue.add(action);
    await _persist();
  }

  Future<void> enqueueAddTimerEvent({
    required String jobId,
    required String action, // start | pause | resume | stop
    String? mechanicId,
  }) async {
    await init();
    final a = OfflineAction(
      id: _uid(),
      type: OfflineActionType.addTimerEvent,
      payload: {
        'jobId': jobId,
        'action': action,
        if (mechanicId != null) 'mechanicId': mechanicId,
      },
      createdAt: DateTime.now(),
    );
    _queue.add(a);
    await _persist();
  }

  Future<void> enqueueSaveSignature({
    required String jobId,
    required String path, // absolute local file path to png
  }) async {
    await init();
    final a = OfflineAction(
      id: _uid(),
      type: OfflineActionType.saveSignature,
      payload: {
        'jobId': jobId,
        'path': path,
      },
      createdAt: DateTime.now(),
    );
    _queue.add(a);
    await _persist();
  }

  Future<void> remove(String id) async {
    _queue.removeWhere((e) => e.id == id);
    await _persist();
  }
}
