import 'dart:async';
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

  int bpm = 60;
  int _lastStableBpm = 60;

  Timer? _debounce;

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

  void _updateBeatAnimation(int bpm) {
    final period = (60000 / bpm).round();
    _controller.duration = Duration(milliseconds: period);
    _controller.forward(from: 0);
  }

  bool _isValidBpm(int v) => v > 40 && v < 200;

  @override
  Widget build(BuildContext context) {
    return Selector<BleManager, int?>(
      selector: (_, ble) => ble.lastPacket?.pulses.last, // ← pulso único parseado
      builder: (_, newPulse, __) {
        if (newPulse == null || !_isValidBpm(newPulse)) {
          newPulse = _lastStableBpm;
        }

        // Debounce
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 500), () {
          if (newPulse != _lastStableBpm) {
            setState(() {
              _lastStableBpm = newPulse!;
              _updateBeatAnimation(_lastStableBpm);
            });
          }
        });

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
                child: Icon(Icons.favorite,
                    size: 60,
                    color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  "$_lastStableBpm BPM",
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
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }
}
