// lib/common/widgets/SleepScore/SleepScoreCalculator.dart

class SleepScoreCalculator {
  static int compute({
    required double movementIndex,     // 0 a 1
    required double apneaEventsPerHr,  // 0 a 30
    required double hrVariability,     // 0 a 1
    required int heartRate,            // BPM
  }) {
    // Movimiento → menos movimiento = mejor
    final movementScore = ((1 - movementIndex).clamp(0.0, 1.0)) * 35;

    // Apnea → penaliza fuertemente
    final apneaNorm = (1 - (apneaEventsPerHr / 30)).clamp(0.0, 1.0);
    final apneaScore = apneaNorm * 35;

    // HRV → contribución moderada
    final hrvScore = hrVariability.clamp(0.0, 1.0) * 20;

    // HR → rango ideal 50..70 BPM (personalizable)
    const minHR = 50;
    const maxHR = 70;
    double hrNorm;
    if (heartRate <= minHR) hrNorm = 1.0;
    else if (heartRate >= maxHR) hrNorm = 0.0;
    else hrNorm = 1 - ((heartRate - minHR) / (maxHR - minHR));
    final hrScore = hrNorm * 10;

    final total = (movementScore + apneaScore + hrvScore + hrScore).clamp(0, 100);
    return total.round();
  }
}
