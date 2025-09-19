import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService._internal();
  static final ConnectivityService instance = ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _statusController = StreamController<bool>.broadcast();

  StreamSubscription? _subscription;
  bool _isOnline = true;

  bool get isOnline => _isOnline;
  Stream<bool> get onStatusChange => _statusController.stream;

  Future<void> init() async {
    final initial = await _connectivity.checkConnectivity();
    bool online;
    if (initial is List<ConnectivityResult>) {
      online = initial.any((r) => r != ConnectivityResult.none);
    } else if (initial is ConnectivityResult) {
      online = initial != ConnectivityResult.none;
    } else {
      online = true;
    }
    _isOnline = online;
    _statusController.add(_isOnline);

    _subscription?.cancel();
    final dynamic stream = _connectivity.onConnectivityChanged;
    _subscription = (stream as Stream).listen((results) {
      List<ConnectivityResult> list;
      if (results is List<ConnectivityResult>) {
        list = results;
      } else if (results is ConnectivityResult) {
        list = [results];
      } else {
        list = const [];
      }
      final online = list.any((r) => r != ConnectivityResult.none);
      if (online != _isOnline) {
        _isOnline = online;
        _statusController.add(_isOnline);
      }
    });
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _statusController.close();
  }
}
