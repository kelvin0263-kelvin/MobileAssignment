import 'package:flutter/material.dart';
import 'package:timer_builder/timer_builder.dart';
import '../utils/app_utils.dart';

class TimerWidget extends StatefulWidget {
  final String jobId;
  final bool isRunning;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onStop;

  const TimerWidget({
    super.key,
    required this.jobId,
    required this.isRunning,
    required this.onStart,
    required this.onPause,
    required this.onStop,
  });

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  DateTime? _startTime;
  Duration _elapsedTime = Duration.zero;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Timer Display
          TimerBuilder.periodic(
            const Duration(seconds: 1),
            builder: (context) {
              Duration currentTime = _elapsedTime;
              if (widget.isRunning && _startTime != null) {
                currentTime += DateTime.now().difference(_startTime!);
              }
              
              return Text(
                DateHelper.formatDuration(currentTime),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          
          // Timer Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (!widget.isRunning) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _startTime = DateTime.now();
                    });
                    widget.onStart();
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('START'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _elapsedTime += DateTime.now().difference(_startTime!);
                      _startTime = null;
                    });
                    widget.onPause();
                  },
                  icon: const Icon(Icons.pause),
                  label: const Text('PAUSE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _elapsedTime = Duration.zero;
                      _startTime = null;
                    });
                    widget.onStop();
                  },
                  icon: const Icon(Icons.stop),
                  label: const Text('STOP'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
