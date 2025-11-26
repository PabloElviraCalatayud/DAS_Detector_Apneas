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

    // Generar 24 valores de movimiento
    final imu = packet.imuSamples;
    final movementActivity = List<double>.filled(24, 0.0);
    if (imu.isNotEmpty) {
      final blockSize = (imu.length / 24).ceil();
      for (int i = 0; i < 24; i++) {
        final start = i * blockSize;
        final end = (start + blockSize).clamp(0, imu.length);
        if (start >= imu.length) break;

        double total = 0;
        for (int j = start; j < end; j++) {
          final s = imu[j];
          total += (s.ax.abs() + s.ay.abs() + s.az.abs()) / 3.0;
        }
        movementActivity[i] = total / (end - start);
      }

      // Normalizar a 0..1
      final maxValue = movementActivity.reduce((a, b) => a > b ? a : b);
      if (maxValue > 0) {
        for (int i = 0; i < 24; i++) {
          movementActivity[i] /= maxValue;
        }
      }
    }

    final data = SensorData(
      heartRate: bpm,
      oxygen: 0,
      movementIndex: _calculateMovement(packet),
      movementActivity: movementActivity, // <- NUEVO
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
