import 'dart:async';
import '../../../data/models/sensor_data_model.dart';

class ApneaDetector {
  final Stream<SensorSnapshot> dataStream;
  final Duration window;
  final _controller = StreamController<int>.broadcast();

  int _events = 0;
  int get totalEvents => _events;

  final List<SensorSnapshot> _buffer = [];

  Stream<int> get apneaEventsStream => _controller.stream;

  StreamSubscription<SensorSnapshot>? _sub;

  ApneaDetector({
    required this.dataStream,
    this.window = const Duration(seconds: 20),
  }) {
    _sub = dataStream.listen(_onData);
  }

  void _onData(SensorSnapshot data) {
    _buffer.add(data);

    final now = data.timestamp;

    _buffer.removeWhere((d) {
      return now - d.timestamp > window.inMilliseconds;
    });

    if (_buffer.length < 5) {
      return;
    }

    final movementSum = _buffer.fold<double>(0.0, (s, e) => s + e.movementIndex);
    final movementAvg = movementSum / _buffer.length;

    final hr = _buffer.map((e) => e.heartRate).toList();

    if (_isApneaPattern(hr, movementAvg)) {
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

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
