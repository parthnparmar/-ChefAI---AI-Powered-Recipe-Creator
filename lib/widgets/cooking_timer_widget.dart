import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/notification_service.dart';

class CookingTimerWidget extends StatefulWidget {
  final String recipeName;
  final int suggestedMinutes;

  const CookingTimerWidget({
    super.key,
    required this.recipeName,
    required this.suggestedMinutes,
  });

  @override
  State<CookingTimerWidget> createState() => _CookingTimerWidgetState();
}

class _CookingTimerWidgetState extends State<CookingTimerWidget> {
  late int _totalSeconds;
  late int _remaining;
  Timer? _timer;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.suggestedMinutes * 60;
    _remaining = _totalSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
    } else {
      if (_remaining == 0) _remaining = _totalSeconds;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_remaining <= 0) {
          _timer?.cancel();
          setState(() => _running = false);
          NotificationService().showTimerNotification(
              widget.recipeName, widget.suggestedMinutes);
        } else {
          setState(() => _remaining--);
        }
      });
      setState(() => _running = true);
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remaining = _totalSeconds;
    });
  }

  String get _timeString {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress =>
      _totalSeconds > 0 ? (_totalSeconds - _remaining) / _totalSeconds : 0;

  @override
  Widget build(BuildContext context) {
    final color = _remaining < 60 && _running
        ? Colors.red
        : Theme.of(context).primaryColor;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.timer, size: 20),
                const SizedBox(width: 8),
                Text('Cooking Timer',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 8,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                Text(
                  _timeString,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ).animate(target: _running ? 1 : 0).shimmer(),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  onPressed: _toggle,
                  icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                  style: IconButton.styleFrom(backgroundColor: color),
                ),
                const SizedBox(width: 12),
                IconButton.outlined(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
