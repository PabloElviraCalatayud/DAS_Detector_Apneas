import 'dart:typed_data';
import 'ble_packet.dart';

class BleDecoder {
  /// Parsea un paquete compacto Option A (20 bytes mínimo)
  static BlePacket? parsePacket(Uint8List data) {
    if (data.length < 11) {
      print("BLE DECODER ERROR: packet too short (${data.length} bytes)");
      return null;
    }

    final b = ByteData.sublistView(data);
    int offset = 0;

    final flags = b.getUint8(offset);
    offset += 1;

    final timestamp = b.getUint64(offset, Endian.little);
    offset += 8;

    final imuCount = b.getUint8(offset);
    offset += 1;

    final pulseCount = b.getUint8(offset);
    offset += 1;

    // ----- IMU -----
    final imuAx = <int>[];
    final imuAy = <int>[];
    final imuAz = <int>[];
    final imuGx = <int>[];
    final imuGy = <int>[];
    final imuGz = <int>[];

    for (int i = 0; i < imuCount; i++) {
      imuAx.add(b.getInt16(offset, Endian.little)); offset += 2;
      imuAy.add(b.getInt16(offset, Endian.little)); offset += 2;
      imuAz.add(b.getInt16(offset, Endian.little)); offset += 2;
      imuGx.add(b.getInt16(offset, Endian.little)); offset += 2;
      imuGy.add(b.getInt16(offset, Endian.little)); offset += 2;
      imuGz.add(b.getInt16(offset, Endian.little)); offset += 2;
    }

    // ----- Pulsos -----
    final pulses = <int>[];
    for (int i = 0; i < pulseCount; i++) {
      pulses.add(b.getUint16(offset, Endian.little));
      offset += 2;
    }

    return BlePacket(
      flags: flags,
      timestamp: timestamp,
      imuAx: imuAx,
      imuAy: imuAy,
      imuAz: imuAz,
      imuGx: imuGx,
      imuGy: imuGy,
      imuGz: imuGz,
      pulses: pulses,
    );
  }
}
