import 'dart:typed_data';
import 'ble_packet.dart';

/// Parsea un paquete "compact" (formato que envía el ESP32).
/// Devuelve BlePacket o null si está truncado o inválido.
BlePacket? decodePacketCompact(Uint8List data) {
  if (data.isEmpty) return null;

  final bd = ByteData.sublistView(data);
  int idx = 0;

  if (idx + 1 > data.length) return null;
  final flags = bd.getUint8(idx);
  idx += 1;

  if (idx + 8 > data.length) return null;
  final timestampLow = bd.getUint32(idx, Endian.little);
  final timestampHigh = bd.getUint32(idx + 4, Endian.little);
  final timestamp = ((timestampHigh << 32) | timestampLow) & 0xFFFFFFFFFFFFFFFF;
  idx += 8;

  if (idx + 2 > data.length) return null;
  final imuCount = bd.getUint8(idx); idx += 1;
  final pulseCount = bd.getUint8(idx); idx += 1;

  final neededForImu = imuCount * 12;
  final neededForPulses = pulseCount * 2;

  if (idx + neededForImu + neededForPulses > data.length) {
    return null; // truncado
  }

  final imuList = <ImuSample>[];
  for (int s = 0; s < imuCount; s++) {
    final ax = bd.getInt16(idx, Endian.little); idx += 2;
    final ay = bd.getInt16(idx, Endian.little); idx += 2;
    final az = bd.getInt16(idx, Endian.little); idx += 2;
    final gx = bd.getInt16(idx, Endian.little); idx += 2;
    final gy = bd.getInt16(idx, Endian.little); idx += 2;
    final gz = bd.getInt16(idx, Endian.little); idx += 2;

    imuList.add(
      ImuSample(
        ax: ax,
        ay: ay,
        az: az,
        gx: gx,
        gy: gy,
        gz: gz,
      ),
    );
  }

  final pulses = <int>[];
  for (int p = 0; p < pulseCount; p++) {
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
