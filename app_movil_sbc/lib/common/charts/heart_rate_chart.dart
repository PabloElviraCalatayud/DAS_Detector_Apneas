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
    return Container(
      height: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          minY: 40,
          maxY: 180,
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 40,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text(
                  "${v.toInt()}",
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (v, _) {
                  if (v < 0 || v >= hours.length) return const SizedBox.shrink();
                  return Text(
                    hours[v.toInt()].toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(data.length, (i) =>
                  FlSpot(i.toDouble(), data[i].toDouble())),
              isCurved: true,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
