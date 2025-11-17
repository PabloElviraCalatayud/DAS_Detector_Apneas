import 'package:flutter/material.dart';
import 'dart:math';

class MovementHeatmap extends StatelessWidget {
  final List<double> activity; // valores entre 0..1

  const MovementHeatmap({super.key, required this.activity});

  /// Genera un color entre verde → amarillo → rojo según el valor.
  Color _colorFor(double value) {
    // clamp por si llega algún valor extraño
    final v = value.clamp(0.0, 1.0);

    // Interpolación lineal
    final r = (255 * v).round();                   // 0 → 255
    final g = (255 * (1 - v)).round();             // 255 → 0
    const b = 80;                                  // toque cálido

    return Color.fromARGB(255, r, g, b);
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
                color: _colorFor(activity[i]),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }
}
