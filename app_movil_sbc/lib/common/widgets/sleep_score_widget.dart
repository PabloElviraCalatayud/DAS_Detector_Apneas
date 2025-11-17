class SleepScoreCalculator {
  static int compute({
    required double movementIndex,     // 0 a 1
    required double apneaEventsPerHr,  // 0 a 30
    required double hrVariability,     // 0 a 1
  }) {
    // Movimiento → sueño profundo = poco movimiento
    final movementScore = (1 - movementIndex) * 50;

    // Respiración → apnea fuerte reduce muchísimo el score
    final breathScore = (1 - (apneaEventsPerHr / 30)).clamp(0.0, 1.0) * 30;

    // Latido → estabilidad cardíaca = sueño más profundo
    final hrScore = hrVariability * 20;

    final total = (movementScore + breathScore + hrScore).clamp(0, 100);

    return total.round();
  }
}
