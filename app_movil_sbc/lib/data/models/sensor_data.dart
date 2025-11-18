import 'package:flutter/foundation.dart';

class SensorData {
  final int heartRate;
  final int oxygen;
  final double movementIndex;
  final double hrv;
  final double apneaEventsPerHour;

  const SensorData({
    required this.heartRate,
    required this.oxygen,
    required this.movementIndex,
    required this.hrv,
    required this.apneaEventsPerHour,
  });

  SensorData copyWith({
    int? heartRate,
    int? oxygen,
    double? movementIndex,
    double? hrv,
    double? apneaEventsPerHour,
  }) {
    return SensorData(
      heartRate: heartRate ?? this.heartRate,
      oxygen: oxygen ?? this.oxygen,
      movementIndex: movementIndex ?? this.movementIndex,
      hrv: hrv ?? this.hrv,
      apneaEventsPerHour: apneaEventsPerHour ?? this.apneaEventsPerHour,
    );
  }
}
