import 'dart:async';
import '../../../data/models/sensor_data_model.dart';

enum ApneaRisk { low, moderate, high }

class ApneaDetector {
  final Stream<SensorSnapshot> dataStream;
  final Duration window;
  final _eventsController = StreamController<int>.broadcast();
  final _riskController = StreamController<ApneaRisk>.broadcast();

  int _events = 0;
  int get totalEvents => _events;

  final List<SensorSnapshot> _buffer = [];
  final List<int> _recentEventTimestamps = [];

  Stream<int> get apneaEventsStream => _eventsController.stream;
  Stream<ApneaRisk> get apneaRiskStream => _riskController.stream;

  StreamSubscription<SensorSnapshot>? _sub;

  // Parámetros ajustables (tuneables)
  final int dropThresholdBpm;        // caída mínima en bpm para considerar evento
  final int recoveryThresholdBpm;    // subida posterior que confirma recuperación
  final double movementThresh;      // movimiento medio máximo para considerar apnea
  final Duration minEventSpacing;    // evitar detección doble inmediata

  ApneaDetector({
    required this.dataStream,
    this.window = const Duration(seconds: 30),
    this.dropThresholdBpm = 8,
    this.recoveryThresholdBpm = 5,
    this.movementThresh = 0.12,
    this.minEventSpacing = const Duration(seconds: 20),
  }) {
    _sub = dataStream.listen(_onData);
  }

  void _onData(SensorSnapshot s) {
    _buffer.add(s);
    final now = s.timestamp;

    _buffer.removeWhere((d) => now - d.timestamp > window.inMilliseconds);

    if (_buffer.length < 4) return;

    // cálculo sencillo: hr series y movement average
    final hrs = _buffer.map((e) => e.heartRate).where((v) => v > 0).toList();
    if (hrs.length < 3) return;

    final movementAvg = _buffer.fold<double>(0.0, (p, e) => p + e.movementIndex) / _buffer.length;

    // detección: busca caída desde el primer valor a un mínimo y posterior recuperación
    final firstHr = hrs.first;
    final minHr = hrs.reduce((a, b) => a < b ? a : b);
    final lastHr = hrs.last;

    final drop = firstHr - minHr;
    final recovery = lastHr - minHr;

    final candidate = drop >= dropThresholdBpm && recovery >= recoveryThresholdBpm && movementAvg <= movementThresh;

    if (candidate) {
      // evitar duplicados muy cercanos
      final lastTs = _recentEventTimestamps.isNotEmpty ? _recentEventTimestamps.last : 0;
      if (s.timestamp - lastTs > minEventSpacing.inMilliseconds) {
        _events++;
        _recentEventTimestamps.add(s.timestamp);
        _eventsController.add(_events);
        _updateRisk();
        // limpiar buffer para evitar detecciones repetidas del mismo evento
        _buffer.clear();
      }
    }

    // limpieza de timestamps antiguos (mantenemos solo últimas 6h)
    final cutoff = DateTime.now().millisecondsSinceEpoch - Duration(hours: 6).inMilliseconds;
    _recentEventTimestamps.removeWhere((t) => t < cutoff);
  }

  // devuelve eventos por hora aproximados (última hora)
  double eventsPerHour() {
    final cutoff = DateTime.now().millisecondsSinceEpoch - Duration(hours: 1).inMilliseconds;
    final recent = _recentEventTimestamps.where((t) => t >= cutoff).length;
    return recent.toDouble();
  }

  void _updateRisk() {
    final eph = eventsPerHour();

    ApneaRisk r;
    if (eph >= 15) {
      r = ApneaRisk.high;
    } else if (eph >= 5) {
      r = ApneaRisk.moderate;
    } else {
      r = ApneaRisk.low;
    }

    _riskController.add(r);
  }

  void dispose() {
    _sub?.cancel();
    _eventsController.close();
    _riskController.close();
  }
}
