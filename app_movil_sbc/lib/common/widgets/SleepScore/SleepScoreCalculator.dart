class SleepScoreCalculator {
  static int compute({
    required double movementIndex,
    required double apneaEventsPerHr,
    required int heartRate,
  }) {
    final mv = movementIndex.clamp(0.0, 1.0);
    final movementScore = (1.0 - mv) * 50.0;

    final ap = (apneaEventsPerHr / 20.0).clamp(0.0, 1.0);
    final apneaScore = (1.0 - ap) * 30.0;

    final minHR = 55;
    final maxHR = 80;

    double hrNorm;

    if (heartRate <= minHR) {
      hrNorm = 1.0;
    } else if (heartRate >= maxHR) {
      hrNorm = 0.0;
    } else {
      hrNorm = 1.0 - ((heartRate - minHR) / (maxHR - minHR));
    }

    final hrScore = hrNorm * 20.0;

    return (movementScore + apneaScore + hrScore).clamp(0.0, 100.0).round();
  }
}
