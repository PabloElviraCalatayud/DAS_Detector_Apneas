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
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 180,
          minY: 40,
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
                getTitlesWidget: (v, _) {
                  int index = v.toInt();
                  if (index < 0 || index >= hours.length) return const SizedBox.shrink();
                  return Text(
                    hours[index].toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(data.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: data[i].toDouble(),
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
