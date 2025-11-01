import 'dart:async';
import 'dart:convert';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'ble_constants.dart';

class BleManager {
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  DiscoveredDevice? connectedDevice;
  QualifiedCharacteristic? writeChar;
  QualifiedCharacteristic? notifyChar;

  StreamSubscription<ConnectionStateUpdate>? _connSub;
  StreamSubscription<List<int>>? _notifySub;

  final StreamController<String> _messages = StreamController.broadcast();
  Stream<String> get messages => _messages.stream;

  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  /// Scan for BLE devices
  Future<Stream<DiscoveredDevice>> scan() async {
    return _ble.scanForDevices(
      withServices: const [],
      scanMode: ScanMode.lowLatency,
      requireLocationServicesEnabled: true,
    );
  }

  /// Connect to device
  Future<void> connect(DiscoveredDevice device) async {
    _connSub = _ble.connectToDevice(id: device.id).listen((update) async {
      switch (update.connectionState) {
        case DeviceConnectionState.connected:
          print("✅ Connected to ${device.id}");
          connectedDevice = device;
          _connectionController.add(true);

          // ✅ Descubrir servicios según nueva API
          print("🔍 Discovering services...");
          await _ble.discoverAllServices(device.id);

          final services = await _ble.getDiscoveredServices(device.id);
          print("📡 Services discovered: $services");

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

          _subscribe();
          break;

        case DeviceConnectionState.disconnected:
          print("⚠️ Disconnected from ${device.id}");
          connectedDevice = null;
          _connectionController.add(false);
          break;

        default:
          break;
      }
    });
  }

  /// Subscribe to notifications
  void _subscribe() {
    if (notifyChar == null) {
      print("⚠️ notifyChar is NULL");
      return;
    }

    print("📡 Subscribing to notifications...");

    _notifySub = _ble.subscribeToCharacteristic(notifyChar!).listen(
          (data) {
        final msg = utf8.decode(data);
        print("📩 Received: $msg");
        _messages.add(msg);
      },
      onError: (e) {
        print("❌ Notification error: $e");
      },
    );
  }

  /// Send message to ESP32
  Future<void> send(String text) async {
    if (writeChar == null || text.isEmpty) return;

    print("📤 Sending: $text");

    await _ble.writeCharacteristicWithResponse(
      writeChar!,
      value: utf8.encode(text),
    );
  }

  /// Disconnect BLE device
  Future<void> disconnect() async {
    print("🔌 Manual disconnect");
    await _connSub?.cancel();
    await _notifySub?.cancel();
    connectedDevice = null;
    _connectionController.add(false);
  }

  /// DO NOT call this when changing pages, only when closing the whole app
  void dispose() {
    _connSub?.cancel();
    _notifySub?.cancel();
    _messages.close();
    _connectionController.close();
  }
}
