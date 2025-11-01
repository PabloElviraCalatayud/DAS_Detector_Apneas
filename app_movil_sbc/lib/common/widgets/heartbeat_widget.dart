import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/bluetooth/ble_manager.dart';

class HeartBeatWidget extends StatefulWidget {
  const HeartBeatWidget({super.key});

  @override
  State<HeartBeatWidget> createState() => _HeartBeatWidgetState();
}

class _HeartBeatWidgetState extends State<HeartBeatWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  int bpm = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  void _updateAnimation(int newBpm) {
    if (newBpm <= 0) {
      newBpm = 60;
    }

    double beatDuration = 60000 / newBpm;

    _controller.duration = Duration(milliseconds: beatDuration.toInt());
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleManager>();

    final raw = ble.lastMessage;
    final match = RegExp(r'\d+').firstMatch(raw);
    int newBpm = match != null ? int.parse(match.group(0)!) : 0;

    if (newBpm != bpm) {
      bpm = newBpm;
      _updateAnimation(bpm);
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite,
            color: Theme.of(context).colorScheme.primary,
            size: 90,
          ),
          const SizedBox(height: 12),
          Text(
            "$bpm BPM",
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
