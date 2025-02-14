import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'dart:math';

class StopwatchWithLock extends StatefulWidget {
  final Duration duration;
  final bool isLocked;
  final double size;

  const StopwatchWithLock({
    required this.duration,
    this.isLocked = true,
    this.size = 100.0,
  });

  @override
  _StopwatchWithLockState createState() => _StopwatchWithLockState();
}

class _StopwatchWithLockState extends State<StopwatchWithLock> {
  late Duration remainingDuration;
  late bool isLocked;
  late double progress;
  late int totalDurationInSeconds;

  @override
  void initState() {
    super.initState();
    remainingDuration = widget.duration;
    isLocked = widget.isLocked;
    totalDurationInSeconds = widget.duration.inSeconds;
    progress = 1.0;
    startCountdown();
  }

  void startCountdown() {
    if (remainingDuration.inSeconds > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && remainingDuration.inSeconds > 0) {
          setState(() {
            remainingDuration -= const Duration(seconds: 1);
            progress = remainingDuration.inSeconds / totalDurationInSeconds;
          });
          startCountdown();
        } else if (remainingDuration.inSeconds == 0) {
          setState(() {
            isLocked = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CircularPercentIndicator(
          radius: widget.size,
          lineWidth: widget.size * 0.08,
          percent: min(progress, 1.0),
          progressColor: isLocked ? Colors.red : Colors.green,
          backgroundColor: Colors.grey[200]!,
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLocked)
              Icon(
                Icons.lock,
                size: widget.size * 0.5,
                color: Colors.grey,
              ),
            SizedBox(height: widget.size * 0.1),
            Text(
              _formatDuration(remainingDuration),
              style: TextStyle(
                fontSize: widget.size * 0.4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
