import 'package:flutter/material.dart';
import '../../common/widgets/heartbeat_widget.dart';
import '../../common/charts/heart_rate_chart.dart';
import '../../common/charts/oxygen_chart.dart';
import '../../common/widgets/spo2_radial_widget.dart';

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {

    final hours = List.generate(24, (i) => i);
    final sampleBPM = [70,72,90,110,95,88,76,70];
    final sampleSpO2 = [98,97,99,96,97,98,99,97];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const HeartBeatWidget(),
            const SizedBox(height: 24),

            HeartRateChartWidget(data: sampleBPM, hours: hours),
            const SizedBox(height: 24),

            const SpO2Widget(value: 97),
            const SizedBox(height: 24),

            OxygenChartWidget(data: sampleSpO2, hours: hours),
          ],
        ),
      ),
    );
  }
}
