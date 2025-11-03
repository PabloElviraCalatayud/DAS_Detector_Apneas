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
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scaleAnimation = Tween(begin: 1.0, end: 1.25)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  void _updateBeatSpeed(int newBpm) {
    if (newBpm <= 0) newBpm = 60;
    double periodMs = 60000 / newBpm;
    _controller.duration = Duration(milliseconds: periodMs.toInt());
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleManager>();
    final raw = ble.lastMessage;
    final match = RegExp(r'\d+').firstMatch(raw);
    int newBpm = match != null ? int.parse(match.group(0)!) : bpm;

    if (newBpm != bpm) {
      bpm = newBpm;
      _updateBeatSpeed(bpm);
    }

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
              "$bpm BPM",
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 38,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
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
