// lib/data/bluetooth/ble_decoder.dart
import 'dart:typed_data';
import 'ble_packet.dart';

/// Parsea un paquete "compact" (Opción A).
/// Devuelve BlePacket o null si el buffer no cumple formato o está truncado.
BlePacket? parsePacket(Uint8List data) {
  if (data.isEmpty) return null;

  // convenient ByteData view for LE reads
  final bd = ByteData.sublistView(data);

  int idx = 0;
  if (idx + 1 > data.length) return null;
  final flags = bd.getUint8(idx);
  idx += 1;

  if (idx + 8 > data.length) return null;
  // timestamp little-endian (uint64). Dart int may handle up to 53 bits safely, but we store as int.
  final timestampLow = bd.getUint32(idx, Endian.little);
  final timestampHigh = bd.getUint32(idx + 4, Endian.little);
  final timestamp = (timestampHigh << 32) | timestampLow;
  idx += 8;

  if (idx + 2 > data.length) return null;
  final imuCount = bd.getUint8(idx);
  idx += 1;
  final pulseCount = bd.getUint8(idx);
  idx += 1;

  // sanity checks: required bytes for IMU and pulses
  final neededForImu = imuCount * 12; // 6 * int16 (2 bytes each)
  final neededForPulses = pulseCount * 2;
  if (idx + neededForImu + neededForPulses > data.length) {
    // truncated
    return null;
  }

  final imuList = <ImuSample>[];
  for (int s = 0; s < imuCount; s++) {
    // Each sample: ax,ay,az,gx,gy,gz int16 LE
    final ax = bd.getInt16(idx, Endian.little); idx += 2;
    final ay = bd.getInt16(idx, Endian.little); idx += 2;
    final az = bd.getInt16(idx, Endian.little); idx += 2;
    final gx = bd.getInt16(idx, Endian.little); idx += 2;
    final gy = bd.getInt16(idx, Endian.little); idx += 2;
    final gz = bd.getInt16(idx, Endian.little); idx += 2;
    imuList.add(ImuSample(ax: ax, ay: ay, az: az, gx: gx, gy: gy, gz: gz));
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
    imuCount: imuCount,
    pulseCount: pulseCount,
    imu: imuList,
    pulses: pulses,
  );
}

/// backward-compatible alias used earlier in examples
BlePacket? decodePacketCompact(Uint8List data) => parsePacket(data);
