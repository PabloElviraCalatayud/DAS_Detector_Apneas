import 'package:flutter/material.dart';
import '../../common/widgets/heartbeat_widget.dart';

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: HeartBeatWidget(bpm: 72),
      ),
    );
  }
}
