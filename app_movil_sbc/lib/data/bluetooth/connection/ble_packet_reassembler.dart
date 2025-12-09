import 'dart:async';
import 'dart:typed_data';

class BlePacketReassembler {
  final List<int> _buffer = [];
  final StreamController<Uint8List> _controller =
  StreamController<Uint8List>.broadcast();

  Stream<Uint8List> get stream => _controller.stream;

  void addFragment(List<int> fragment) {
    _buffer.addAll(fragment);

    while (true) {
      if (_buffer.length < 11) return;

      final data = Uint8List.fromList(_buffer);
      final bd = ByteData.sublistView(data);

      int offset = 1 + 8;
      final imuCount = bd.getUint8(offset++);
      final pulseCount = bd.getUint8(offset++);
      final expected = 11 + (imuCount * 12) + (pulseCount * 2);

      if (_buffer.length < expected) return;

      final pkt = Uint8List.fromList(_buffer.sublist(0, expected));
      _controller.add(pkt);

      _buffer.removeRange(0, expected);
    }
  }

  void clear() {
    _buffer.clear();
  }

  void dispose() {
    _controller.close();
  }
}
