import 'dart:async';
import 'package:flutter/foundation.dart';
import 'sensor_data.dart';
import '../bluetooth/ble_packet.dart';

class SensorDataModel {
  SensorDataModel._internal();
  static final SensorDataModel instance = SensorDataModel._internal();

  final StreamController<SensorData> _controller =
  StreamController<SensorData>.broadcast();

  Stream<SensorData> get sensorStream => _controller.stream;

  SensorData? lastData;

  void process(BlePacket packet) {
    final int bpm = packet.pulses.isNotEmpty ? packet.pulses.last : 0;

    final data = SensorData(
      heartRate: bpm,
      oxygen: 0, // No hay oxígeno real
      movementIndex: _calculateMovement(packet),
      hrv: _estimateHrv(packet),
      apneaEventsPerHour: 0,
    );

    lastData = data;
    _controller.add(data);
  }

  double _calculateMovement(BlePacket packet) {
    double total = 0;
    final imu = packet.imuSamples;
    if (imu.isEmpty) {
      return 0;
    }

    for (final s in imu) {
      total += (s.ax.abs() + s.ay.abs() + s.az.abs()) / 3.0;
    }

    return total / imu.length;
  }

  double _estimateHrv(BlePacket packet) {
    final samples = packet.pulses;
    if (samples.length < 2) {
      return 0;
    }

    final rr = samples[samples.length - 1] - samples[samples.length - 2];
    return (rr.abs() * 0.1);
  }
}
