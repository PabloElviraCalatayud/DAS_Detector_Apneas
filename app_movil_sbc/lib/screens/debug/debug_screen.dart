import 'package:flutter/material.dart';
import '../../data/bluetooth/codec/ble_packet.dart';


class DebugScreen extends StatefulWidget {
  final Stream<BlePacket> packetStream;

  const DebugScreen({
    super.key,
    required this.packetStream,
  });

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  ImuSample? lastImu;

  @override
  void initState() {
    super.initState();
    widget.packetStream.listen((packet) {
      if (packet.imuSamples.isNotEmpty) {
        setState(() {
          lastImu = packet.imuSamples.first;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final imu = lastImu;

    return Scaffold(
      appBar: AppBar(
        title: Text('Debug IMU'),
      ),
      body: imu == null
          ? Center(
        child: Text('Esperando datos...'),
      )
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ax: ${imu.ax}', style: TextStyle(fontSize: 22)),
            SizedBox(height: 4),
            Text('ay: ${imu.ay}', style: TextStyle(fontSize: 22)),
            SizedBox(height: 4),
            Text('az: ${imu.az}', style: TextStyle(fontSize: 22)),
            SizedBox(height: 16),
            Text('gx: ${imu.gx}', style: TextStyle(fontSize: 22)),
            SizedBox(height: 4),
            Text('gy: ${imu.gy}', style: TextStyle(fontSize: 22)),
            SizedBox(height: 4),
            Text('gz: ${imu.gz}', style: TextStyle(fontSize: 22)),
          ],
        ),
      ),
    );
  }
}
