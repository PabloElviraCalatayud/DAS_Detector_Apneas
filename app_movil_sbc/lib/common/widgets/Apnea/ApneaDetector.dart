import 'dart:async';
import '../../../data/models/sensor_data_model.dart';

enum ApneaRisk { low, moderate, high }

class ApneaDetector {
  // -------------------------------------------------------
  //                       SINGLETON
  // -------------------------------------------------------
  ApneaDetector._internal();
  static final ApneaDetector instance = ApneaDetector._internal();

  // -------------------------------------------------------
  //          VARIABLES PRINCIPALES DEL DETECTOR
  // -------------------------------------------------------
  final Duration window = const Duration(seconds: 30);

  int _eventsTotal = 0;
  int get totalEvents => _eventsTotal;

  final List<SensorSnapshot> _buffer = [];
  final List<int> _eventTimestamps = [];

  final _eventsController = StreamController<int>.broadcast();
  final _riskController = StreamController<ApneaRisk>.broadcast();

  Stream<int> get apneaEventsStream => _eventsController.stream;
  Stream<ApneaRisk> get apneaRiskStream => _riskController.stream;

  StreamSubscription<SensorSnapshot>? _sub;

  final int dropThresholdBpm = 8;
  final int recoveryThresholdBpm = 5;
  final double movementThresh = 0.12;
  final Duration minEventSpacing = const Duration(seconds: 20);

  bool _initialized = false;

  // Registros de tiempo para resets
  int _lastHourlyReset = DateTime.now().hour;
  int _lastDailyReset = DateTime.now().day;

  // -------------------------------------------------------
  //               INICIALIZAR EL DETECTOR
  // -------------------------------------------------------
  void initialize() {
    if (_initialized) return;
    _initialized = true;

    _sub = SensorDataModel.instance.dataStream.listen(_onData);
  }

  // -------------------------------------------------------
  //            LÓGICA PRINCIPAL DE CADA MUESTRA
  // -------------------------------------------------------
  void _onData(SensorSnapshot s) {
    _handleHourlyReset();
    _handleDailyReset();

    final now = s.timestamp;
    _buffer.add(s);

    // Mantener ventana de 30 s
    _buffer.removeWhere((d) => now - d.timestamp > window.inMilliseconds);

    if (_buffer.length < 4) return;

    final hrs = _buffer.map((e) => e.heartRate).where((v) => v > 0).toList();
    if (hrs.length < 3) return;

    final movementAvg = _buffer.fold<double>(0.0, (p, e) => p + e.movementIndex) / _buffer.length;

    final first = hrs.first;
    final minHr = hrs.reduce((a, b) => a < b ? a : b);
    final last = hrs.last;

    final drop = first - minHr;
    final recovery = last - minHr;

    final candidate = drop >= dropThresholdBpm &&
        recovery >= recoveryThresholdBpm &&
        movementAvg <= movementThresh;

    if (candidate) {
      final lastTs = _eventTimestamps.isNotEmpty ? _eventTimestamps.last : 0;

      if (s.timestamp - lastTs > minEventSpacing.inMilliseconds) {
        _eventsTotal++;
        _eventTimestamps.add(now);

        _eventsController.add(_eventsTotal);
        _updateRisk();

        _buffer.clear();
      }
    }

    // mantener solo últimas 6 horas
    final cutoff = DateTime.now().millisecondsSinceEpoch - 3600000 * 6;
    _eventTimestamps.removeWhere((t) => t < cutoff);
  }

  // -------------------------------------------------------
  //              RESET AUTOMÁTICO CADA HORA
  // -------------------------------------------------------
  void _handleHourlyReset() {
    final currentHour = DateTime.now().hour;
    if (currentHour != _lastHourlyReset) {
      _eventTimestamps.clear();
      _lastHourlyReset = currentHour;
    }
  }

  // -------------------------------------------------------
  //          RESET AUTOMÁTICO CADA 24 HORAS
  // -------------------------------------------------------
  void _handleDailyReset() {
    final currentDay = DateTime.now().day;
    if (currentDay != _lastDailyReset) {
      _eventsTotal = 0;
      _eventsController.add(_eventsTotal);
      _lastDailyReset = currentDay;
    }
  }

  // -------------------------------------------------------
  //                 EVENTOS POR HORA (AHI)
  // -------------------------------------------------------
  double eventsPerHour() {
    final cutoff = DateTime.now().millisecondsSinceEpoch - 3600000;
    return _eventTimestamps.where((t) => t >= cutoff).length.toDouble();
  }

  // -------------------------------------------------------
  //                     RIESGO
  // -------------------------------------------------------
  void _updateRisk() {
    final ahi = eventsPerHour();

    ApneaRisk risk;
    if (ahi >= 15) {
      risk = ApneaRisk.high;
    } else if (ahi >= 5) {
      risk = ApneaRisk.moderate;
    } else {
      risk = ApneaRisk.low;
    }

    _riskController.add(risk);
  }

  // -------------------------------------------------------
  //      NO SE ELIMINA EL DETECTOR (PERSISTE SIEMPRE)
  // -------------------------------------------------------
  void dispose() {}
}