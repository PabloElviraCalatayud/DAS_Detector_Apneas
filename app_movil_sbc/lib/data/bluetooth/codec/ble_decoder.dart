import 'dart:typed_data';
import 'ble_packet.dart';

class BleDecoder {
  static BlePacket? decodeCompact(Uint8List data) {
    if (data.isEmpty) return null;
    try {
      return BlePacket.fromBytes(data);
    } catch (_) {
      return null;
    }
  }
}
