import 'package:flutter/material.dart';

class HeartBeatWidget extends StatefulWidget {
  final int bpm;

  const HeartBeatWidget({
    super.key,
    required this.bpm,
  });

  @override
  State<HeartBeatWidget> createState() => _HeartBeatWidgetState();
}

class _HeartBeatWidgetState extends State<HeartBeatWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Animación basada en BPM
    double beatDurationMs = 60000 / widget.bpm;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: beatDurationMs.toInt()),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant HeartBeatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.bpm != widget.bpm) {
      double beatDurationMs = 60000 / widget.bpm;
      _controller.duration = Duration(milliseconds: beatDurationMs.toInt());
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            "${widget.bpm} BPM",
            style: Theme.of(context).textTheme.titleLarge,
          )
        ],
      ),
    );
  }
}
