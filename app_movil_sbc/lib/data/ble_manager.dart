import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ble_constants.dart';

class BleManager {
  final flutterReactiveBle = FlutterReactiveBle();

  final List<DiscoveredDevice> devices = [];
  DiscoveredDevice? connectedDevice;
  QualifiedCharacteristic? writeChar;
  QualifiedCharacteristic? notifyChar;

  StreamSubscription<ConnectionStateUpdate>? _connectionSub;
  StreamSubscription<List<int>>? _notifySub;

  final StreamController<String> _messages = StreamController.broadcast();
  Stream<String> get messages => _messages.stream;

  /* --------------------------------------------- */
  /* PERMISOS BLE                                 */
  /* --------------------------------------------- */
  Future<bool> _checkPermissions() async {
    if (Platform.isAndroid) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();
      return statuses.values.every((status) => status.isGranted);
    }
    return true;
  }

  /* --------------------------------------------- */
  /* ESCANEO DE DISPOSITIVOS                      */
  /* --------------------------------------------- */
  Future<void> scan(Function(DiscoveredDevice) onDeviceFound) async {
    final hasPerms = await _checkPermissions();
    if (!hasPerms) throw Exception("Permisos BLE denegados");

    devices.clear();

    flutterReactiveBle.scanForDevices(withServices: []).listen((device) {
      if (device.name.isNotEmpty && !devices.any((d) => d.id == device.id)) {
        devices.add(device);
        onDeviceFound(device);
      }
    });
  }

  /* --------------------------------------------- */
  /* CONEXIÓN BLE                                 */
  /* --------------------------------------------- */
  Future<void> connect(DiscoveredDevice device, Function(String) onStatus) async {
    onStatus("Conectando a ${device.name}...");
    _connectionSub = flutterReactiveBle.connectToDevice(id: device.id).listen(
          (update) async {
        switch (update.connectionState) {
          case DeviceConnectionState.connected:
            connectedDevice = device;
            onStatus("Conectado a ${device.name}");

            // Configura las características BLE personalizadas
            writeChar = QualifiedCharacteristic(
              serviceId: BleConstants.serviceUuid,
              characteristicId: BleConstants.writeCharacteristicUuid,
              deviceId: device.id,
            );

            notifyChar = QualifiedCharacteristic(
              serviceId: BleConstants.serviceUuid,
              characteristicId: BleConstants.notifyCharacteristicUuid,
              deviceId: device.id,
            );

            _subscribeToNotifications(onStatus);
            break;

          case DeviceConnectionState.disconnected:
            connectedDevice = null;
            onStatus("Desconectado");
            break;

          default:
            break;
        }
      },
      onError: (e) => onStatus("Error conexión: $e"),
    );
  }

  /* --------------------------------------------- */
  /* SUSCRIPCIÓN A NOTIFICACIONES                 */
  /* --------------------------------------------- */
  void _subscribeToNotifications(Function(String) onStatus) {
    if (notifyChar == null) return;
    _notifySub = flutterReactiveBle.subscribeToCharacteristic(notifyChar!).listen(
          (data) {
        final msg = utf8.decode(data);
        _messages.add(msg);
      },
      onError: (e) => onStatus("Error en notificaciones: $e"),
    );
  }

  /* --------------------------------------------- */
  /* ENVÍO DE DATOS AL ESP32                      */
  /* --------------------------------------------- */
  Future<void> send(String text) async {
    if (writeChar == null || text.isEmpty) {
      throw Exception("Característica de escritura no inicializada o texto vacío");
    }
    try {
      await flutterReactiveBle.writeCharacteristicWithResponse(
        writeChar!,
        value: utf8.encode(text),
      );
      print("📤 Enviado: $text");
    } catch (e) {
      throw Exception("Error enviando datos: $e");
    }
  }

  /* --------------------------------------------- */
  /* DESCONECTAR DISPOSITIVO                      */
  /* --------------------------------------------- */
  Future<void> disconnect() async {
    await _connectionSub?.cancel();
    await _notifySub?.cancel();
    connectedDevice = null;
  }
}
