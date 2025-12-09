import 'dart:async';

import '../../../data/models/sensor_data.dart';


class ApneaDetector {
  final Stream<SensorData> sensorStream;
  final Duration window;
  final _controller = StreamController<int>.broadcast();

  int _events = 0;
  int get totalEvents => _events;

  final List<SensorData> _buffer = [];

  Stream<int> get apneaEventsStream => _controller.stream;

  ApneaDetector({
    required this.sensorStream,
    this.window = const Duration(seconds: 20),
  }) {
    sensorStream.listen(_onData);
  }

  void _onData(SensorData data) {
    _buffer.add(data);
    final now = DateTime.now().millisecondsSinceEpoch;

    _buffer.removeWhere((d) {
      return now - d.timestamp > window.inMilliseconds;
    });

    if (_buffer.length < 5) {
      return;
    }

    final movementAvg = _buffer.map((e) => e.movementIndex).reduce((a, b) => a + b) / _buffer.length;
    final hrList = _buffer.map((e) => e.heartRate).toList();

    if (_isApneaPattern(hrList, movementAvg)) {
      _events++;
      _controller.add(_events);
      _buffer.clear();
    }
  }

  bool _isApneaPattern(List<int> hr, double movementAvg) {
    if (hr.length < 4) {
      return false;
    }

    final first = hr.first;
    final last = hr.last;

    final drop = first - last;

    return drop >= 5 && movementAvg < 0.15;
  }
}

