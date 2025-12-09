import 'package:flutter/material.dart';
import 'SleepScoreCalculator.dart';

class SleepScoreCard extends StatelessWidget {
  final double movementIndex;      // 0..1
  final double apneaEventsPerHr;   // 0..30
  final int heartRate;             // BPM

  const SleepScoreCard({
    super.key,
    required this.movementIndex,
    required this.apneaEventsPerHr,
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

  String _movementLabel(double v) {
    if (v < 0.2) return "Muy bajo";
    if (v < 0.4) return "Bajo";
    if (v < 0.6) return "Moderado";
    if (v < 0.8) return "Alto";
    return "Muy alto";
  }

  @override
  Widget build(BuildContext context) {
    final score = SleepScoreCalculator.compute(
      movementIndex: movementIndex,
      apneaEventsPerHr: apneaEventsPerHr,
      heartRate: heartRate,
    );

    final color = _categoryColor(context, score);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hotel, size: 26, color: color),
              const SizedBox(width: 8),
              const Text(
                "Calidad del Sueño",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) {
                      return AlertDialog(
                        title: const Text("Parámetros utilizados"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Movimiento: ${_movementLabel(movementIndex)} "
                                  "${(movementIndex.clamp(0.0, 1.0) * 100).toStringAsFixed(1)}%"
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Eventos de apnea/h: ${apneaEventsPerHr.toStringAsFixed(1)}",
                            ),
                            const SizedBox(height: 6),
                            Text("Ritmo cardíaco: $heartRate BPM"),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cerrar"),
                          )
                        ],
                      );
                    },
                  );
                },
                child: Icon(
                  Icons.info_outline,
                  size: 22,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "$score / 100",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            _category(score),
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
