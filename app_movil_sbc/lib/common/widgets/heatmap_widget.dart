import 'package:flutter/material.dart';

class MovementHeatmap extends StatelessWidget {
  final List<double> activity; // valores 0..1
  final double height;
  final double spacing;

  const MovementHeatmap({
    super.key,
    required this.activity,
    this.height = 60,
    this.spacing = 4,
  });

  /// Escala deseada:
  /// 0.0 → azul
  /// 0.5 → amarillo
  /// 1.0 → rojo
  Color _mapColor(double v, bool dark) {
    v = v.clamp(0.0, 1.0);

    // AZULES (0 → 0.50)
    const deepBlue = Color(0xFF0D47A1);   // azul muy oscuro
    const midBlue  = Color(0xFF1976D2);   // azul medio
    const lightBlue = Color(0xFF64B5F6);  // azul claro (NO verde)

    // ALTOS (0.50 → 1.0)
    const yellow = Color(0xFFFFEB3B);
    const orange = Color(0xFFFF9800);
    const red = Color(0xFFE53935);

    final opacity = dark ? 0.85 : 1.0;

    if (v < 0.25) {
      // 0.00 → 0.25
      return Color.lerp(deepBlue, midBlue, v / 0.25)!.withOpacity(opacity);
    }
    else if (v < 0.50) {
      // 0.25 → 0.50
      return Color.lerp(midBlue, lightBlue, (v - 0.25) / 0.25)!.withOpacity(opacity);
    }
    else if (v < 0.75) {
      // 0.50 → 0.75: amarillo → naranja
      return Color.lerp(yellow, orange, (v - 0.50) / 0.25)!.withOpacity(opacity);
    }
    else {
      // 0.75 → 1.00: naranja → rojo
      return Color.lerp(orange, red, (v - 0.75) / 0.25)!.withOpacity(opacity);
    }
  }



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: List.generate(activity.length, (i) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: spacing / 2),
              decoration: BoxDecoration(
                color: _mapColor(activity[i], isDark),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }),
      ),
    );
  }
}
