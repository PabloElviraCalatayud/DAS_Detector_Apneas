import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/widgets/SleepScore/SleepScoreCard.dart';
import '../../common/widgets/SleepScore/SleepScoreCalculator.dart';
import '../../common/widgets/heartbeat_widget.dart';
import '../../common/widgets/heatmap_widget.dart';
import '../../common/charts/heart_rate_chart.dart';

import '../../data/models/sensor_data.dart';
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

    // Actualizar pantalla con cada dato recibido
    SensorDataModel.instance.sensorStream.listen((data) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final sensorModel = SensorDataModel.instance;

    final data = sensorModel.lastData;

    final movementActivity = data?.movementActivity ?? List.filled(24, 0.0);
    final movementIndex = data?.movementIndex ?? 0.0;
    final hrv = data?.hrv ?? 0.0;
    final heartRate = data?.heartRate ?? 0;

    final sleepScore = SleepScoreCalculator.compute(
      movementIndex: movementIndex,
      apneaEventsPerHr: apneaEvents.toDouble(),
      hrVariability: hrv,
      heartRate: heartRate,
    );

    final hourlyData = sensorModel.hourlyHistory.map((h) => h.average.toInt()).toList();
    final hourlyLabels = sensorModel.hourlyHistory.map((h) {
      final dt = DateTime.fromMillisecondsSinceEpoch(h.hourTimestamp * 1000);
      return dt.hour; // se puede mejorar con hora:min para mostrar en eje X
    }).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SleepScoreCard(
              movementIndex: movementIndex,
              apneaEventsPerHr: apneaEvents.toDouble(),
              hrVariability: hrv,
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
