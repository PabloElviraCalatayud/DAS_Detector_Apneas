import 'dart:typed_data';

class ImuSample {
  final double ax, ay, az;
  final double gx, gy, gz;

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

    final ts = _readUint64(bytes, offset);
    offset += 8;

    final imuCount = bytes[offset];
    offset += 1;

    final pulseCount = bytes[offset];
    offset += 1;

    final imuSamples = <ImuSample>[];

    // ---- Parse IMU ----
    for (int i = 0; i < imuCount; i++) {
      final rawAx = _readInt16(bytes, offset);
      final rawAy = _readInt16(bytes, offset + 2);
      final rawAz = _readInt16(bytes, offset + 4);
      final rawGx = _readInt16(bytes, offset + 6);
      final rawGy = _readInt16(bytes, offset + 8);
      final rawGz = _readInt16(bytes, offset + 10);
      offset += 12;

      // Convert x100 scale from ESP32
      imuSamples.add(ImuSample(
        ax: rawAx / 100.0,
        ay: rawAy / 100.0,
        az: rawAz / 100.0,
        gx: rawGx / 100.0,
        gy: rawGy / 100.0,
        gz: rawGz / 100.0,
      ));
    }

    // ---- Pulses ----
    final pulses = <int>[];
    for (int i = 0; i < pulseCount; i++) {
      pulses.add(_readUint16(bytes, offset));
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
