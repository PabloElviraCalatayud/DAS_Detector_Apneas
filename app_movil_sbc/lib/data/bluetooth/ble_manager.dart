// lib/data/bluetooth/ble_manager.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'ble_connection.dart';
import 'ble_decoder.dart';
import 'ble_packet.dart';

class BleManager extends ChangeNotifier {
  final BleConnection _conn = BleConnection();

  BlePacket? lastPacket;
  String lastMessage = "";

  final _msgController = StreamController<String>.broadcast();
  Stream<String> get messages => _msgController.stream;

  Stream<bool> get connectionStream =>
      _conn.onConnectionChanged.map((d) => d != null);

  DiscoveredDevice? get connectedDevice => _conn.connectedDevice;

  BleManager() {
    // Cada vez que llegan datos binarios del ESP32 → decodificamos
    _conn.onRawData.listen(_handleRawPacket);
  }

  // === PARSER PRINCIPAL ===
  void _handleRawPacket(Uint8List data) {
    // Debug: mostrar bytes en consola
    if (kDebugMode) {
      print(
          "RAW BLE (${data.length}): ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}");
    }

    // Utilizamos el decoder creado en ble_decoder.dart
    final pkt = BleDecoder.parsePacket(data);
    if (pkt == null) {
      if (kDebugMode) print("BLE MANAGER: packet inválido o incompleto");
      return;
    }

    lastPacket = pkt;

    // Mensaje para UI (temporal)
    lastMessage =
    "IMU=${pkt.imuAx.length}  PULSE=${pkt.pulses.isNotEmpty ? pkt.pulses.last : '-'}";

    _msgController.add(lastMessage);

    notifyListeners();
  }

  // ==== MÉTODOS BLE ====

  Future<Stream<DiscoveredDevice>> scan() => _conn.scan();

  Future<void> connect(DiscoveredDevice d) => _conn.connect(d);

  Future<void> disconnect() => _conn.disconnect();

  Future<void> send(String text) => _conn.send(text);

  Future<void> write(Uint8List data) => _conn.write(data);

  Future<int> requestMtu(int mtu) => _conn.requestMtu(mtu);

  @override
  void dispose() {
    _msgController.close();
    _conn.dispose();
    super.dispose();
  }
}
