// lib/common/widgets/SleepScore/SleepScoreCard.dart

import 'package:flutter/material.dart';
import 'SleepScoreCalculator.dart';

class SleepScoreCard extends StatelessWidget {
  final double movementIndex;      // 0..1
  final double apneaEventsPerHr;   // 0..30
  final double hrVariability;      // 0..1
  final int heartRate;             // BPM

  const SleepScoreCard({
    super.key,
    required this.movementIndex,
    required this.apneaEventsPerHr,
    required this.hrVariability,
    required this.heartRate,
  });

  String _category(int score) {
    if (score >= 85) return "Excelente";
    if (score >= 70) return "Bueno";
    if (score >= 55) return "Regular";
    if (score >= 40) return "Malo";
    return "Muy malo";
  }

  Color _categoryColor(BuildContext context, int score) {
    final c = Theme.of(context).colorScheme;

    if (score >= 85) return c.primary;
    if (score >= 70) return c.secondary;
    if (score >= 55) return Colors.amber;
    if (score >= 40) return Colors.deepOrangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final score = SleepScoreCalculator.compute(
      movementIndex: movementIndex,
      apneaEventsPerHr: apneaEventsPerHr,
      hrVariability: hrVariability,
      heartRate: heartRate,
    );

    final color = _categoryColor(context, score);

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          builder: (_) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Detalles del sueño",
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 20),

                  Text("Movimiento: ${(movementIndex * 100).round()}%"),
                  Text("Eventos de apnea/hora: ${apneaEventsPerHr.toStringAsFixed(1)}"),
                  Text("Variabilidad cardíaca: ${(hrVariability * 100).round()}%"),
                  Text("Frecuencia cardíaca: $heartRate BPM"),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: score.toDouble()),
              duration: const Duration(milliseconds: 900),
              builder: (context, value, _) {
                return SizedBox(
                  height: 140,
                  width: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: value / 100,
                        strokeWidth: 10,
                        strokeCap: StrokeCap.round,
                        color: color,
                        backgroundColor:
                        Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                      ),
                      Text(
                        value.toInt().toString(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            Text(
              _category(score),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              "Pulsa para más detalles",
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
