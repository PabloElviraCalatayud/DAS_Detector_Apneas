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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bars = List.generate(data.length, (i) {
      return BarChartGroupData(
        x: hours[i],
        barRods: [
          BarChartRodData(
            toY: data[i].toDouble(),
            width: 18,
            borderRadius: BorderRadius.circular(6),
            color: theme.colorScheme.primary,
          ),
        ],
      );
    });

    return Container(
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          gridData: FlGridData(
            show: true,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (_) => FlLine(
              color: theme.colorScheme.onSurface.withOpacity(0.06),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          minY: 40,
          maxY: 180,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 40,
                getTitlesWidget: (v, _) => Text(
                  "${v.toInt()}",
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                reservedSize: 32,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final hour = v.toInt();
                  return Text(
                    hour.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  );
                },
                reservedSize: 32,
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: bars,
        ),
      ),
    );
  }
}
