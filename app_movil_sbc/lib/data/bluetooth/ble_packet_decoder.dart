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

  @override
  String toString() =>
      "IMU(ax=$ax ay=$ay az=$az | gx=$gx gy=$gy gz=$gz)";
}

class PulseSample {
  final int bpm;
  PulseSample(this.bpm);

  @override
  String toString() => "Pulse($bpm)";
}

class BlePacket {
  final int flags;
  final int timestamp;
  final List<ImuSample> imuSamples;
  final List<PulseSample> pulseSamples;

  BlePacket({
    required this.flags,
    required this.timestamp,
    required this.imuSamples,
    required this.pulseSamples,
  });

  @override
  String toString() =>
      "BlePacket(ts=$timestamp imu=${imuSamples.length} pulse=${pulseSamples.length})";
}

class BlePacketDecoder {
  static BlePacket decode(Uint8List p) {
    final bd = ByteData.sublistView(p);
    int offset = 0;

    if (p.length < 11) {
      return BlePacket(
        flags: 0,
        timestamp: 0,
        imuSamples: [],
        pulseSamples: [],
      );
    }

    final flags = bd.getUint8(offset++);

    final low = bd.getUint32(offset, Endian.little);
    final high = bd.getUint32(offset + 4, Endian.little);
    final timestamp = (high << 32) | low;
    offset += 8;

    final countImu = bd.getUint8(offset++);
    final countPulse = bd.getUint8(offset++);

    final imu = <ImuSample>[];

    for (int i = 0; i < countImu; i++) {
      final ax = bd.getInt16(offset, Endian.little) / 100.0; offset += 2;
      final ay = bd.getInt16(offset, Endian.little) / 100.0; offset += 2;
      final az = bd.getInt16(offset, Endian.little) / 100.0; offset += 2;

      final gx = bd.getInt16(offset, Endian.little) / 100.0; offset += 2;
      final gy = bd.getInt16(offset, Endian.little) / 100.0; offset += 2;
      final gz = bd.getInt16(offset, Endian.little) / 100.0; offset += 2;

      imu.add(ImuSample(
        ax: ax, ay: ay, az: az,
        gx: gx, gy: gy, gz: gz,
      ));
    }

    final pulses = <PulseSample>[];

    for (int i = 0; i < countPulse; i++) {
      final bpm = bd.getUint16(offset, Endian.little);
      offset += 2;
      pulses.add(PulseSample(bpm));
    }

    return BlePacket(
      flags: flags,
      timestamp: timestamp,
      imuSamples: imu,
      pulseSamples: pulses,
    );
  }
}
