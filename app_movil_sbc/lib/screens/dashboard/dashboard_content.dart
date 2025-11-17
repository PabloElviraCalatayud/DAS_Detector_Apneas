import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import '../../common/widgets/heartbeat_widget.dart';
import '../../common/widgets/heatmap_widget.dart';
import '../../common/widgets/sleep_score_widget.dart';
import '../../common/widgets/spo2_radial_widget.dart';

import '../../common/charts/heart_rate_chart.dart';
import '../../common/charts/oxygen_chart.dart';
import '../../data/bluetooth/ble_manager.dart';

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleManager>();

    // Valores simulados por ahora
    final hours = List.generate(24, (i) => i);

    // Movement Index (simulación por ahora)
    final movementActivity = List.generate(24, (i) => (i % 6) / 6);

    final score = SleepScoreCalculator.compute(
      movementIndex: 0.4,
      apneaEventsPerHr: 3,
      hrVariability: 0.6,
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const HeartBeatWidget(),
            const SizedBox(height: 24),

            Text("Sleep Score: $score / 100",
                style: Theme.of(context).textTheme.headlineMedium),

            const SizedBox(height: 16),
            MovementHeatmap(activity: movementActivity),
            const SizedBox(height: 24),

            const SpO2Widget(),
            const SizedBox(height: 24),

            HeartRateChartWidget(data: [70,72,90,80,78], hours: hours),
            const SizedBox(height: 24),

            OxygenChartWidget(data: [98,97,99,95,97], hours: hours),
          ],
        ),
      ),
    );
  }
}
