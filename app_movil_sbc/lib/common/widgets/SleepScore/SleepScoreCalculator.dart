class SleepScoreCalculator {
  static int compute({
    required double movementIndex,
    required double apneaEventsPerHr,
    required int heartRate,
  }) {
    double mv = movementIndex.clamp(0.0, 1.0);
    double movementScore = (1.0 - mv) * 50.0;

    double ap = (apneaEventsPerHr / 30.0).clamp(0.0, 1.0);
    double apneaScore = (1.0 - ap) * 40.0;

    const int minHR = 50;
    const int maxHR = 70;

    double hrNorm;

    if (heartRate <= minHR) {
      hrNorm = 1.0;
    } else {
      if (heartRate >= maxHR) {
        hrNorm = 0.0;
      } else {
        hrNorm = 1.0 - ((heartRate - minHR) / (maxHR - minHR));
      }
    }

    double hrScore = hrNorm * 10.0;

    return (movementScore + apneaScore + hrScore).clamp(0.0, 100.0).round();
  }
}
