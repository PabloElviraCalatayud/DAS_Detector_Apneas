import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/widgets/Apnea/ApneaCard.dart';
import '../../common/widgets/Apnea/ApneaDetector.dart';

import '../../common/widgets/SleepScore/SleepScoreCard.dart';
import '../../common/widgets/SleepScore/SleepScoreCalculator.dart';

import '../../common/widgets/heatmap_widget.dart';
import '../../common/widgets/heartbeat_widget.dart';
import '../../common/charts/heart_rate_chart.dart';

import '../../data/models/sensor_data.dart';
import '../../data/models/sensor_data_model.dart';

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  late final ApneaDetector _apneaDetector;
  int apneaEvents = 0;
  final List<int> heartHistory = [];

  @override
  void initState() {
    super.initState();

    _apneaDetector = ApneaDetector(
      sensorStream: SensorDataModel.instance.sensorStream,
    );

    _apneaDetector.apneaEventsStream.listen((value) {
      setState(() {
        apneaEvents = value;
      });
    });

    SensorDataModel.instance.sensorStream.listen((data) {
      if (data.heartRate > 0) {
        setState(() {
          heartHistory.add(data.heartRate);
          if (heartHistory.length > 100) {
            heartHistory.removeAt(0);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<SensorData>(
        stream: SensorDataModel.instance.sensorStream,
        builder: (context, snapshot) {
          final data = snapshot.data;

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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ApneaCard(apneaEvents: apneaEvents),
                const SizedBox(height: 24),

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
                  data: heartHistory,
                  hours: List.generate(heartHistory.length, (i) => i),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
