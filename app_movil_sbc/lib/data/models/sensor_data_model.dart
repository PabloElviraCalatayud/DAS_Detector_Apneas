import 'dart:async';
import 'sensor_data.dart';
import '../bluetooth/codec/ble_packet.dart';
import 'dart:math';

class HourlyHeartRate {
  final int hourTimestamp;
  double sum = 0;
  int count = 0;

  HourlyHeartRate(this.hourTimestamp);

  void add(int heartRate) {
    sum += heartRate;
    count++;
  }

  double get average => count > 0 ? sum / count : 0;
}

class SensorDataModel {
  SensorDataModel._internal();
  static final SensorDataModel instance = SensorDataModel._internal();

  final StreamController<SensorData> _controller =
  StreamController<SensorData>.broadcast();
  Stream<SensorData> get sensorStream => _controller.stream;

  SensorData? lastData;

  final List<HourlyHeartRate> hourlyHistory = [];

  void addHeartRate(int heartRate, int timestamp) {
    final hourStart = timestamp - (timestamp % 3600);

    if (hourlyHistory.isEmpty || hourlyHistory.last.hourTimestamp != hourStart) {
      hourlyHistory.add(HourlyHeartRate(hourStart));
      if (hourlyHistory.length > 12) {
        hourlyHistory.removeAt(0);
      }
    }

    hourlyHistory.last.add(heartRate);
  }

  void process(BlePacket packet) {
    final int bpm = packet.pulses.isNotEmpty ? packet.pulses.last : 0;
    final int ts = packet.timestamp;

    addHeartRate(bpm, ts);

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

          final ax = s.ax;
          final ay = s.ay;
          final az = s.az - 1.0;

          final mag = sqrt(ax * ax + ay * ay + az * az);
          total += mag;
        }

        movementActivity[i] = (end - start) > 0 ? total / (end - start) : 0;
      }

      final maxValue =
      movementActivity.reduce((a, b) => a > b ? a : b);
      if (maxValue > 0) {
        for (int i = 0; i < 24; i++) {
          movementActivity[i] = movementActivity[i] / maxValue;
        }
      }
    }

    final data = SensorData(
      timestamp: ts,
      heartRate: bpm,
      oxygen: 0,
      movementIndex: _calculateMovement(packet).clamp(0.0, 1.0),
      movementActivity: movementActivity,
      apneaEventsPerHour: 0,
    );

    lastData = data;
    _controller.add(data);
  }

  double _calculateMovement(BlePacket packet) {
    final imu = packet.imuSamples;
    if (imu.isEmpty) return 0;

    double total = 0;

    for (final s in imu) {
      final ax = s.ax;
      final ay = s.ay;
      final az = s.az - 1.0;

      final mag = sqrt(ax * ax + ay * ay + az * az);
      total += mag;
    }

    return total / imu.length;
  }

  double _estimateHrv(BlePacket packet) {
    final samples = packet.pulses;
    if (samples.length < 2) return 0;
    final rr = samples[samples.length - 1] - samples[samples.length - 2];
    return rr.abs() * 0.1;
  }
}
