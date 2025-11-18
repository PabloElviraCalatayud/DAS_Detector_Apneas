import 'dart:typed_data';

class ImuSample {
  final int ax, ay, az;
  final int gx, gy, gz;

  ImuSample({
    required this.ax,
    required this.ay,
    required this.az,
    required this.gx,
    required this.gy,
    required this.gz,
  });
}

class BlePacket {
  final int flags;
  final int timestamp;
  final List<ImuSample> imuSamples;
  final List<int> pulses;

  BlePacket({
    required this.flags,
    required this.timestamp,
    required this.imuSamples,
    required this.pulses,
  });

  factory BlePacket.fromBytes(Uint8List bytes) {
    int offset = 0;

    final flags = bytes[offset];
    offset += 1;

    // timestamp uint64 LE
    final ts = _readUint64(bytes, offset);
    offset += 8;

    final imuCount = bytes[offset];
    offset += 1;

    final pulseCount = bytes[offset];
    offset += 1;

    // Parse IMU samples
    final imuSamples = <ImuSample>[];
    for (int i = 0; i < imuCount; i++) {
      final ax = _readInt16(bytes, offset);
      final ay = _readInt16(bytes, offset + 2);
      final az = _readInt16(bytes, offset + 4);
      final gx = _readInt16(bytes, offset + 6);
      final gy = _readInt16(bytes, offset + 8);
      final gz = _readInt16(bytes, offset + 10);
      offset += 12;

      imuSamples.add(ImuSample(
        ax: ax,
        ay: ay,
        az: az,
        gx: gx,
        gy: gy,
        gz: gz,
      ));
    }

    // Pulses uint16
    final pulses = <int>[];
    for (int i = 0; i < pulseCount; i++) {
      final p = _readUint16(bytes, offset);
      pulses.add(p);
      offset += 2;
    }

    return BlePacket(
      flags: flags,
      timestamp: ts,
      imuSamples: imuSamples,
      pulses: pulses,
    );
  }

  // =======================
  // LE READ HELPERS
  // =======================

  static int _readInt16(Uint8List data, int offset) {
    return ByteData.sublistView(data, offset, offset + 2)
        .getInt16(0, Endian.little);
  }

  static int _readUint16(Uint8List data, int offset) {
    return ByteData.sublistView(data, offset, offset + 2)
        .getUint16(0, Endian.little);
  }

  static int _readUint64(Uint8List data, int offset) {
    final bd = ByteData.sublistView(data, offset, offset + 8);
    return bd.getUint64(0, Endian.little);
  }
}
