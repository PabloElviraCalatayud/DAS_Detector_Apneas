import 'package:flutter/material.dart';

class MovementHeatmap extends StatelessWidget {
  final List<double> activity; // valores 0..1

  const MovementHeatmap({
    super.key,
    required this.activity,
  });

  Color _colorFor(BuildContext context, double value) {
    final v = value.clamp(0.0, 1.0);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Colores base del theme
    final surface = Theme.of(context).colorScheme.surface;
    final mid = Theme.of(context).colorScheme.secondary;
    final high = Theme.of(context).colorScheme.primary;

    if (v < 0.5) {
      final t = v / 0.5;
      return Color.lerp(surface, mid, t)!;
    } else {
      final t = (v - 0.5) / 0.5;
      return Color.lerp(mid, high, t)!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(activity.length, (i) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: _colorFor(context, activity[i]),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          );
        }),
      ),
    );
  }
}
