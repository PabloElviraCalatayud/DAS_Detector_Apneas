import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/sensor_data_model.dart';

class HeartBeatWidget extends StatefulWidget {
  const HeartBeatWidget({super.key});

  @override
  State<HeartBeatWidget> createState() => _HeartBeatWidgetState();
}

class _HeartBeatWidgetState extends State<HeartBeatWidget>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  int _currentBpm = 0;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scaleAnimation = Tween(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _sub = SensorDataModel.instance.dataStream.listen((data) {
      final bpm = data.heartRate;
      if (bpm != _currentBpm) {
        setState(() {
          _currentBpm = bpm;
          _updateBeatAnimation(bpm);
        });
      }
    });
  }

  void _updateBeatAnimation(int bpm) {
    if (bpm <= 0) {
      _controller.duration = const Duration(milliseconds: 5000);
    } else {
      final ms = (60000 / bpm).round();
      _controller.duration = Duration(milliseconds: ms);
    }
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Icon(
              Icons.favorite,
              size: 60,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              "$_currentBpm BPM",
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 38,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    super.dispose();
  }
}
