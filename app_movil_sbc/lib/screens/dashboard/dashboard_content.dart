import 'package:flutter/material.dart';

import '../../common/widgets/SleepScore/SleepScoreCard.dart';
import '../../common/widgets/SleepScore/SleepScoreCalculator.dart';
import '../../common/widgets/heartbeat_widget.dart';
import '../../common/widgets/heatmap_widget.dart';
import '../../common/charts/heart_rate_chart.dart';

import '../../data/models/sensor_data_model.dart';

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  int apneaEvents = 0;

  @override
  void initState() {
    super.initState();

    // AHORA ESCUCHAMOS dataStream (no sensorStream del modelo)
    SensorDataModel.instance.dataStream.listen((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = SensorDataModel.instance;
    final data = model.lastData;

    final movementActivity = data?.movementActivity ?? List.filled(24, 0.0);
    final movementIndex = data?.movementIndex ?? 0.0;
    final heartRate = data?.heartRate ?? 0;

    final sleepScore = SleepScoreCalculator.compute(
      movementIndex: movementIndex,
      apneaEventsPerHr: apneaEvents.toDouble(),
      heartRate: heartRate,
    );

    final hourlyData = model.hourlyHistory.map((h) => h.average.toInt()).toList();

    final hourlyLabels = model.hourlyHistory.map((h) {
      int ts = h.hourTimestamp;

      if (ts < 10000000000) {
        ts *= 1000;
      }

      return DateTime.fromMillisecondsSinceEpoch(ts).hour;
    }).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SleepScoreCard(
              movementIndex: movementIndex,
              apneaEventsPerHr: apneaEvents.toDouble(),
              heartRate: heartRate,
            ),

            const SizedBox(height: 24),

            MovementHeatmap(activity: movementActivity),

            const SizedBox(height: 24),

            const HeartBeatWidget(),

            const SizedBox(height: 24),

            HeartRateChartWidget(
              data: hourlyData,
              hours: hourlyLabels,
            ),
          ],
        ),
      ),
    );
  }
}
