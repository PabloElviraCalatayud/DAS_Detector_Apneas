import 'package:flutter/material.dart';

class ApneaRiskCard extends StatelessWidget {
  final int totalEvents;
  final double eventsPerHour;
  final double movementIndex;
  final int heartRate;

  const ApneaRiskCard({
    super.key,
    required this.totalEvents,
    required this.eventsPerHour,
    required this.movementIndex,
    required this.heartRate,
  });

  String _riskLabel(double ahi) {
    if (ahi < 5) return "Normal";
    if (ahi < 15) return "Leve";
    if (ahi < 30) return "Moderado";
    return "Grave";
  }

  Color _riskColor(BuildContext context, double ahi) {
    final c = Theme.of(context).colorScheme;
    if (ahi < 5) return c.primary;
    if (ahi < 15) return Colors.amber;
    if (ahi < 30) return Colors.deepOrangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _riskColor(context, eventsPerHour);

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) {
            return AlertDialog(
              title: const Text("¿Cómo se calcula?"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "Este sistema estima riesgo de apnea basándose en:\n"
                        "• Caídas bruscas de ritmo cardíaco\n"
                        "• Períodos prolongados sin movimiento\n"
                        "• Frecuencia y patrón temporal de eventos\n\n"
                        "Modelo inspirado en métodos usados por Garmin, Fitbit y Apple Watch, "
                        "aunque simplificado para ejecución local.",
                  ),
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
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.18),
              blurRadius: 14,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_rounded, color: color, size: 28),
                const SizedBox(width: 10),
                const Text(
                  "Riesgo de Apnea",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _riskLabel(eventsPerHour),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Eventos totales",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalEvents.toString(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Eventos por hora (AHI)",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      eventsPerHour.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: theme.colorScheme.onSurface.withOpacity(0.08),
              ),
              child: LayoutBuilder(
                builder: (_, c) {
                  final pct = (eventsPerHour / 30).clamp(0.0, 1.0);
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: c.maxWidth * pct,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
