import 'dart:async';
import 'dart:math';
import '../../data/bluetooth/codec/ble_packet.dart';

class HourlyHistoryEntry {
  final int hourTimestamp;
  final double average;

  HourlyHistoryEntry({
    required this.hourTimestamp,
    required this.average,
  });
}

class SensorSnapshot {
  final int timestamp;
  final double movementIndex;
  final List<double> movementActivity;
  final int heartRate;

  SensorSnapshot({
    required this.timestamp,
    required this.movementIndex,
    required this.movementActivity,
    required this.heartRate,
  });
}

class SensorDataModel {
  SensorDataModel._internal();
  static final SensorDataModel instance = SensorDataModel._internal();

  final _controller = StreamController<SensorSnapshot>.broadcast();
  Stream<SensorSnapshot> get dataStream => _controller.stream;

  SensorSnapshot? lastData;

  final List<HourlyHistoryEntry> hourlyHistory = [];

  final List<double> _dayActivity = List<double>.filled(24, 0);

  double _prevDyn = 0.0;
  static const double _gravity = 9.81;

  void updateFromPacket(BlePacket pkt) {
    final now = DateTime.now().millisecondsSinceEpoch;

    double movementIndex = 0;

    if (pkt.imuSamples.isNotEmpty) {
      final imu = pkt.imuSamples.first;

      final a = sqrt(
          imu.ax * imu.ax +
              imu.ay * imu.ay +
              imu.az * imu.az
      );

      final dyn = (a - _gravity).abs();
      final diff = (dyn - _prevDyn).abs();
      _prevDyn = dyn;

      movementIndex = min(diff / 2.0, 1.0);
    }

    int bpm = 0;
    if (pkt.pulses.isNotEmpty) {
      bpm = pkt.pulses.last;
    }

    final hour = DateTime.now().hour;
    _dayActivity[hour] = movementIndex;

    final snapshot = SensorSnapshot(
      timestamp: now,
      movementIndex: movementIndex,
      movementActivity: List<double>.from(_dayActivity),
      heartRate: bpm,
    );

    lastData = snapshot;
    _controller.add(snapshot);

    _updateHourlyHistory(now, movementIndex);
  }

  void _updateHourlyHistory(int ts, double movement) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    final hourStart = DateTime(dt.year, dt.month, dt.day, dt.hour).millisecondsSinceEpoch;

    final index = hourlyHistory.indexWhere((h) => h.hourTimestamp == hourStart);

    if (index == -1) {
      hourlyHistory.add(
        HourlyHistoryEntry(hourTimestamp: hourStart, average: movement),
      );
    } else {
      final old = hourlyHistory[index];
      final avg = (old.average + movement) / 2;
      hourlyHistory[index] = HourlyHistoryEntry(
        hourTimestamp: hourStart, average: avg,
      );
    }
  }
}