import 'package:flutter/material.dart';
import 'SleepScoreCalculator.dart';

class SleepScoreCard extends StatelessWidget {
  final double movementIndex;
  final double apneaEventsPerHr;
  final int heartRate;

  const SleepScoreCard({
    super.key,
    required this.movementIndex,
    required this.apneaEventsPerHr,
    required this.heartRate,
  });

  String _category(int s) {
    if (s >= 85) return "Excelente";
    if (s >= 70) return "Bueno";
    if (s >= 55) return "Regular";
    if (s >= 40) return "Malo";
    return "Muy malo";
  }

  String _movementLabel(double v) {
    if (v < 0.2) return "Muy bajo";
    if (v < 0.4) return "Bajo";
    if (v < 0.6) return "Medio";
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

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) {
            return AlertDialog(
              title: const Text("¿Cómo se calcula la calidad del sueño?"),
              content: const Text(
                "Este valor combina tres factores:\n\n"
                    "• Movimiento nocturno: Similar a Garmin o Fitbit, "
                    "menos movimiento implica sueño más profundo.\n\n"
                    "• Ritmo cardíaco nocturno: Valores más bajos indican "
                    "mayor recuperación (similar a Apple Watch y Oura).\n\n"
                    "• Eventos de apnea: Cuantos más eventos por hora, "
                    "mayor impacto negativo.\n\n"
                    "Cada componente se normaliza y pondera para producir "
                    "una puntuación entre 0 y 100.",
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
      child: Container(
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
                const Icon(Icons.hotel, size: 26, color: Colors.blue),
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
                                "Movimiento: ${_movementLabel(movementIndex)}",
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Eventos de apnea/h: "
                                    "${apneaEventsPerHr.toStringAsFixed(1)}",
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
                color: Colors.blue,
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
      ),
    );
  }
}
