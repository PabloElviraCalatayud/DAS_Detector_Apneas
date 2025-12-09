import 'dart:typed_data';
import 'ble_packet.dart';

class BleDecoder {
  static BlePacket? decodeCompact(Uint8List data) {
    if (data.isEmpty) {
      return null;
    }

    final bd = ByteData.sublistView(data);
    int idx = 0;

    if (idx + 1 > data.length) {
      return null;
    }
    final flags = bd.getUint8(idx);
    idx += 1;

    if (idx + 8 > data.length) {
      return null;
    }
    final low = bd.getUint32(idx, Endian.little);
    final high = bd.getUint32(idx + 4, Endian.little);
    final timestamp = ((high << 32) | low) & 0xFFFFFFFFFFFFFFFF;
    idx += 8;

    if (idx + 2 > data.length) {
      return null;
    }
    final imuCount = bd.getUint8(idx);
    idx += 1;
    final pulseCount = bd.getUint8(idx);
    idx += 1;

    final imuBytes = imuCount * 12;
    final pulseBytes = pulseCount * 2;

    if (idx + imuBytes + pulseBytes > data.length) {
      return null;
    }

    final imuList = <ImuSample>[];
    for (int i = 0; i < imuCount; i++) {
      final ax = bd.getInt16(idx, Endian.little); idx += 2;
      final ay = bd.getInt16(idx, Endian.little); idx += 2;
      final az = bd.getInt16(idx, Endian.little); idx += 2;
      final gx = bd.getInt16(idx, Endian.little); idx += 2;
      final gy = bd.getInt16(idx, Endian.little); idx += 2;
      final gz = bd.getInt16(idx, Endian.little); idx += 2;

      const scale = 0.01;

      imuList.add(ImuSample(
        ax: ax * scale,
        ay: ay * scale,
        az: az * scale,
        gx: gx * scale,
        gy: gy * scale,
        gz: gz * scale,
      ));
    }

    final pulses = <int>[];
    for (int i = 0; i < pulseCount; i++) {
      final v = bd.getUint16(idx, Endian.little);
      idx += 2;
      pulses.add(v);
    }

    return BlePacket(
      flags: flags,
      timestamp: timestamp,
      imuSamples: imuList,
      pulses: pulses,
    );
  }
}
