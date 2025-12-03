import 'package:flutter/material.dart';

class MovementHeatmap extends StatelessWidget {
  final List<double> activity;
  final double height;
  final double spacing;

  const MovementHeatmap({
    super.key,
    required this.activity,
    this.height = 60,
    this.spacing = 4,
  });

  Color _mapColor(double v, bool dark) {
    v = v.clamp(0.0, 1.0);

    const deepBlue = Color(0xFF0D47A1);
    const midBlue = Color(0xFF1976D2);
    const lightBlue = Color(0xFF64B5F6);
    const yellow = Color(0xFFFFEB3B);
    const orange = Color(0xFFFF9800);
    const red = Color(0xFFE53935);

    final opacity = dark ? 0.85 : 1.0;

    if (v < 0.25) return Color.lerp(deepBlue, midBlue, v / 0.25)!.withOpacity(opacity);
    if (v < 0.50) return Color.lerp(midBlue, lightBlue, (v - 0.25) / 0.25)!.withOpacity(opacity);
    if (v < 0.75) return Color.lerp(yellow, orange, (v - 0.50) / 0.25)!.withOpacity(opacity);
    return Color.lerp(orange, red, (v - 0.75) / 0.25)!.withOpacity(opacity);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.monitor_heart,
                  size: 26,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text(
                "Mapa de Movimiento",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: height,
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
          ),
        ],
      ),
    );
  }
}
