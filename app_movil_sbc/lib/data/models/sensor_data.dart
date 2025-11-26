import 'package:flutter/foundation.dart';

class SensorData {
  final int heartRate;
  final int oxygen;
  final double movementIndex;
  final List<double> movementActivity;
  final double hrv;
  final double apneaEventsPerHour;

  const SensorData({
    required this.heartRate,
    required this.oxygen,
    required this.movementIndex,
    this.movementActivity = const [],
    required this.hrv,
    required this.apneaEventsPerHour,
  });

  SensorData copyWith({
    int? heartRate,
    int? oxygen,
    double? movementIndex,
    List<double>? movementActivity,
    double? hrv,
    double? apneaEventsPerHour,
  }) {
    return SensorData(
      heartRate: heartRate ?? this.heartRate,
      oxygen: oxygen ?? this.oxygen,
      movementIndex: movementIndex ?? this.movementIndex,
      movementActivity: movementActivity ?? this.movementActivity,
      hrv: hrv ?? this.hrv,
      apneaEventsPerHour: apneaEventsPerHour ?? this.apneaEventsPerHour,
    );
  }
}
