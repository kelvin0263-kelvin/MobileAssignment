import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/app_utils.dart';

class TimeTrackerCard extends StatefulWidget {
  final void Function(Duration totalElapsed) onTimeUpdate;
  final Duration initialElapsed;

  const TimeTrackerCard({
    super.key,
    required this.onTimeUpdate,
    this.initialElapsed = Duration.zero,
  });

  @override
  State<TimeTrackerCard> createState() => _TimeTrackerCardState();
}

class _TimeTrackerCardState extends State<TimeTrackerCard> {
  Duration _totalElapsed = Duration.zero;
  DateTime? _sessionStart;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _totalElapsed = widget.initialElapsed;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (_sessionStart != null) return;
    setState(() {
      _sessionStart = DateTime.now();
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  void _pause() {
    if (_sessionStart == null) return;
    final now = DateTime.now();
    setState(() {
      _totalElapsed += now.difference(_sessionStart!);
      _sessionStart = null;
    });
    _timer?.cancel();
    widget.onTimeUpdate(_totalElapsed);
  }

  void _stop() {
    _pause();
    setState(() {
      _totalElapsed = Duration.zero;
    });
    widget.onTimeUpdate(_totalElapsed);
  }

  Duration get _displayElapsed {
    if (_sessionStart == null) return _totalElapsed;
    return _totalElapsed + DateTime.now().difference(_sessionStart!);
  }

  @override
  Widget build(BuildContext context) {
    final running = _sessionStart != null;
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
            Center(
              child: Column(
                children: [
                  Text(
                    DateHelper.formatDuration(_displayElapsed),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 4),
                  Text('Total time: ${_displayElapsed.inMinutes}m', style: AppTextStyles.caption),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!running)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _start,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start'),
                    ),
                  )
                else ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pause,
                      icon: const Icon(Icons.pause),
                      label: const Text('Pause'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, foregroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _stop,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ],
            )
          ],
        ),
      ),
    );
  }
}


