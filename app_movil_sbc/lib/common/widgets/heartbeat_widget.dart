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

  int _currentBpm = 0;
  Timer? _debounce;

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
  }

  void _updateBeatAnimation(int bpm) {
    if (bpm <= 0) {
      _controller.duration = const Duration(milliseconds: 5000);
    } else {
      final period = (60000 / bpm).round();
      _controller.duration = Duration(milliseconds: period);
    }

    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Selector<BleManager, int>(
      selector: (_, ble) => ble.latestHeartRate,
      builder: (_, bpm, __) {
        final incoming = bpm;

        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 300), () {
          if (incoming != _currentBpm) {
            setState(() {
              _currentBpm = incoming;
              _updateBeatAnimation(_currentBpm);
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
