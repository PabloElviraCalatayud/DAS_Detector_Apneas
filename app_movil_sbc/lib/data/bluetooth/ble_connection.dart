// lib/data/bluetooth/ble_connection.dart

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'ble_constants.dart';

/// Maneja:
///  - conexión BLE
///  - suscripción de notificaciones
///  - reconstrucción de paquetes fragmentados
///  - escritura en características
class BleConnection {
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  DiscoveredDevice? connectedDevice;

  // Notificaciones reconstruidas (paquetes completos)
  final StreamController<Uint8List> _rawController =
  StreamController.broadcast();
  Stream<Uint8List> get onRawData => _rawController.stream;

  // Cambios de conexión
  final StreamController<DiscoveredDevice?> _connController =
  StreamController.broadcast();
  Stream<DiscoveredDevice?> get onConnectionChanged =>
      _connController.stream;

  StreamSubscription<ConnectionStateUpdate>? _connSub;
  StreamSubscription<List<int>>? _notifySub;

  QualifiedCharacteristic? _notifyChar;
  QualifiedCharacteristic? _writeChar;

  // Buffer interno para reconstruir paquetes
  final List<int> _rxBuffer = [];

  bool get isConnected => connectedDevice != null;

  // -------------------------------------------------------------
  // SCAN
  // -------------------------------------------------------------
  Future<Stream<DiscoveredDevice>> scan() async {
    return _ble.scanForDevices(
      withServices: const [],
      scanMode: ScanMode.lowLatency,
    );
  }

  // -------------------------------------------------------------
  // CONNECT
  // -------------------------------------------------------------
  Future<void> connect(DiscoveredDevice device) async {
    await _connSub?.cancel();

    _connSub = _ble
        .connectToDevice(
      id: device.id,
      connectionTimeout: const Duration(seconds: 10),
    )
        .listen((update) async {
      switch (update.connectionState) {
        case DeviceConnectionState.connected:
          connectedDevice = device;
          _connController.add(connectedDevice);

          await _ble.discoverAllServices(device.id);

          _writeChar = QualifiedCharacteristic(
            deviceId: device.id,
            serviceId: BleConstants.serviceUuid,
            characteristicId: BleConstants.writeCharacteristicUuid,
          );

          _notifyChar = QualifiedCharacteristic(
            deviceId: device.id,
            serviceId: BleConstants.serviceUuid,
            characteristicId: BleConstants.notifyCharacteristicUuid,
          );

          _subscribeToNotifications();
          break;

        case DeviceConnectionState.disconnected:
          connectedDevice = null;
          _connController.add(null);
          await _notifySub?.cancel();
          _notifySub = null;
          _notifyChar = null;
          _writeChar = null;
          break;

        default:
          break;
      }
    });
  }

  // -------------------------------------------------------------
  // NOTIFICATION REASSEMBLY (RECONSTRUCTOR DE PAQUETES)
  // -------------------------------------------------------------
  void _subscribeToNotifications() {
    if (_notifyChar == null) return;

    _notifySub = _ble.subscribeToCharacteristic(_notifyChar!).listen(
      _onNotificationFragment,
      onError: (e) {
        print("BLE notify error: $e");
      },
    );
  }

  /// Recibe FRAGMENTOS BLE y reconstruye paquetes completos.
  void _onNotificationFragment(List<int> fragment) {
    // Añadir fragmento recibido al buffer
    _rxBuffer.addAll(fragment);

    // Procesar mientras haya suficientes bytes
    while (true) {
      // Header mínimo = 11 bytes
      if (_rxBuffer.length < 11) {
        return;
      }

      final data = Uint8List.fromList(_rxBuffer);
      final bd = ByteData.sublistView(data);

      int offset = 0;

      // flags
      offset += 1;

      // timestamp uint64
      offset += 8;

      // counts
      final countImu = bd.getUint8(offset++);
      final countPulse = bd.getUint8(offset++);

      // tamaño esperado completo
      final expected =
          1 + 8 + 2 + (countImu * 12) + (countPulse * 2);

      // No hay suficientes bytes aún
      if (_rxBuffer.length < expected) {
        return;
      }

      // Extraer paquete completo
      final pkt = _rxBuffer.sublist(0, expected);
      _rawController.add(Uint8List.fromList(pkt));

      // Eliminar el paquete del buffer
      _rxBuffer.removeRange(0, expected);

      // Si queda basura o varios paquetes pegados, sigue
    }
  }

  // -------------------------------------------------------------
  // DISCONNECT
  // -------------------------------------------------------------
  Future<void> disconnect() async {
    await _connSub?.cancel();
    _connSub = null;

    connectedDevice = null;
    _connController.add(null);

    await _notifySub?.cancel();
    _notifySub = null;

    _notifyChar = null;
    _writeChar = null;

    _rxBuffer.clear();
  }

  // -------------------------------------------------------------
  // WRITE (TEXT)
  // -------------------------------------------------------------
  Future<void> send(String text) async {
    if (_writeChar == null) return;
    await _ble.writeCharacteristicWithResponse(
      _writeChar!,
      value: text.codeUnits,
    );
  }

  // -------------------------------------------------------------
  // WRITE (BINARY)
  // -------------------------------------------------------------
  Future<void> write(Uint8List data) async {
    if (_writeChar == null) return;
    await _ble.writeCharacteristicWithResponse(
      _writeChar!,
      value: data,
    );
  }

  // -------------------------------------------------------------
  // MTU
  // -------------------------------------------------------------
  Future<int> requestMtu(int mtu) async {
    if (connectedDevice == null) throw Exception("No connected device");

    final result =
    await _ble.requestMtu(deviceId: connectedDevice!.id, mtu: mtu);

    return result;
  }

  // -------------------------------------------------------------
  // DISPOSE
  // -------------------------------------------------------------
  void dispose() {
    _rawController.close();
    _connController.close();
    _connSub?.cancel();
    _notifySub?.cancel();
  }
}
