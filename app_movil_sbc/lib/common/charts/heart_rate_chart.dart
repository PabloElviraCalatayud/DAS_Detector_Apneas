import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class HeartRateChartWidget extends StatelessWidget {
  final List<int> data;
  final List<int> hours;

  const HeartRateChartWidget({
    super.key,
    required this.data,
    required this.hours,
  });

  Color _colorForHR(int bpm, bool dark) {
    if (bpm < 60) return dark ? const Color(0xFF6EE7B7) : const Color(0xFF10B981);
    if (bpm < 80) return dark ? const Color(0xFFA7F3D0) : const Color(0xFF34D399);
    if (bpm < 100) return dark ? const Color(0xFFFDE68A) : const Color(0xFFFBBF24);
    return dark ? const Color(0xFFFCA5A5) : const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    final bars = List.generate(data.length, (i) {
      return BarChartGroupData(
        x: hours[i],
        barRods: [
          BarChartRodData(
            toY: data[i].toDouble(),
            width: 10,
            borderRadius: BorderRadius.circular(4),
            color: _colorForHR(data[i], dark),
          ),
        ],
      );
    });

    return Container(
      height: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: BarChart(
        BarChartData(
          minY: 40,
          maxY: 180,
          gridData: FlGridData(
            show: true,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (_) => FlLine(
              color: theme.colorScheme.onSurface.withOpacity(0.07),
              strokeWidth: 0.6,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: bars,
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 40,
                getTitlesWidget: (v, _) {
                  return Text(
                    "${v.toInt()}",
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  );
                },
                reservedSize: 28,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (value, _) {
                  final hour = value.toInt();

                  return SizedBox(
                    width: 24, // 👈 mismo ancho para TODO
                    child: Center(
                      child: hour % 4 == 0
                          ? Text(
                        hour.toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      )
                          : Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
