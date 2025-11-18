import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/widgets/SleepScore/SleepScoreCalculator.dart';
import '../../common/widgets/SleepScore/SleepScoreCard.dart';
import '../../common/widgets/heartbeat_widget.dart';
import '../../common/widgets/heatmap_widget.dart';
import '../../common/widgets/spo2_radial_widget.dart';

import '../../common/charts/heart_rate_chart.dart';
import '../../common/charts/oxygen_chart.dart';
import '../../data/bluetooth/ble_manager.dart';

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleManager>();

    //
    // ================================
    // DATOS SIMULADOS (TEMPORAL)
    // ================================
    final movementActivity = List<double>.generate(24, (i) => (i % 6) / 6);
    final heartRateData = [70, 72, 90, 80, 78, 76, 74];
    final spo2Data = [98, 97, 99, 95, 97, 98, 97];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const HeartBeatWidget(),
            const SizedBox(height: 24),

            SleepScoreCard(
              movementIndex: 0.4,
              apneaEventsPerHr: 3,
              hrVariability: 0.6,
              heartRate: 72, // 💓 simulado por ahora
            ),

            const SizedBox(height: 24),
            MovementHeatmap(activity: movementActivity),
            const SizedBox(height: 24),

            const SpO2Widget(),
            const SizedBox(height: 24),

            HeartRateChartWidget(
              data: heartRateData,
              hours: List.generate(heartRateData.length, (i) => i),
            ),
            const SizedBox(height: 24),

            OxygenChartWidget(
              data: spo2Data,
              hours: List.generate(spo2Data.length, (i) => i),
            ),
          ],
        ),
      ),
    );
  }
}
