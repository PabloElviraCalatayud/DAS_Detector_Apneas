class SensorData {
  final int timestamp;
  final int heartRate;
  final int oxygen;
  final double movementIndex;
  final List<double> movementActivity;
  final double apneaEventsPerHour;

  const SensorData({
    required this.timestamp,
    required this.heartRate,
    required this.oxygen,
    required this.movementIndex,
    this.movementActivity = const [],
    required this.apneaEventsPerHour,
  });

  SensorData copyWith({
    int? timestamp,
    int? heartRate,
    int? oxygen,
    double? movementIndex,
    List<double>? movementActivity,
    double? apneaEventsPerHour,
  }) {
    return SensorData(
      timestamp: timestamp ?? this.timestamp,
      heartRate: heartRate ?? this.heartRate,
      oxygen: oxygen ?? this.oxygen,
      movementIndex: movementIndex ?? this.movementIndex,
      movementActivity: movementActivity ?? this.movementActivity,
      apneaEventsPerHour: apneaEventsPerHour ?? this.apneaEventsPerHour,
    );
  }
}
