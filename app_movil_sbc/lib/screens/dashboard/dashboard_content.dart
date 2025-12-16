import 'package:flutter/material.dart';

import '../../common/widgets/Apnea/ApneaCard.dart';
import '../../common/widgets/SleepScore/SleepScoreCard.dart';
import '../../common/widgets/SleepScore/SleepScoreCalculator.dart';
import '../../common/widgets/heartbeat_widget.dart';
import '../../common/widgets/heatmap_widget.dart';
import '../../common/charts/heart_rate_chart.dart';

import '../../data/models/sensor_data_model.dart';
import '../../common/widgets/Apnea/ApneaDetector.dart';

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final ApneaDetector _detector = ApneaDetector.instance;

  @override
  void initState() {
    super.initState();

    _detector.initialize();

    _detector.apneaEventsStream.listen((_) {
      if (mounted) setState(() {});
    });

    _detector.apneaRiskStream.listen((_) {
      if (mounted) setState(() {});
    });

    SensorDataModel.instance.dataStream.listen((_) {
      if (mounted) setState(() {});
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
      apneaEventsPerHr: _detector.eventsPerHour(),
      heartRate: heartRate,
    );

    final hourlyData = List.generate(
      24,
          (i) {
            final index = (i + SensorDataModel.instance.currentHourIndex) % 24;
            return SensorDataModel.instance.hourlyHeartRate[index].average;
      },
    );


    final hourlyLabels = List.generate(
      24,
          (i) {
        final hour = (i + SensorDataModel.instance.currentHourIndex) % 24;
        return hour;
      },
    );




    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ApneaRiskCard(
              totalEvents: _detector.totalEvents,
              eventsPerHour: _detector.eventsPerHour(),
              movementIndex: movementIndex,
              heartRate: heartRate,
            ),

            const SizedBox(height: 24),

            SleepScoreCard(
              movementIndex: movementIndex,
              apneaEventsPerHr: _detector.eventsPerHour(),
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
