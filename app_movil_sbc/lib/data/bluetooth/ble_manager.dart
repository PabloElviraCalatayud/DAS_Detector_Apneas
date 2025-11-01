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

  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  Future<Stream<DiscoveredDevice>> scan() async {
    return _ble.scanForDevices(
      withServices: const [],
      scanMode: ScanMode.lowLatency,
      requireLocationServicesEnabled: true,
    );
  }

  Future<void> connect(DiscoveredDevice device) async {
    _connSub = _ble.connectToDevice(id: device.id).listen((update) async {
      switch (update.connectionState) {
        case DeviceConnectionState.connected:
          connectedDevice = device;
          _connectionController.add(true);

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
          connectedDevice = null;
          _connectionController.add(false);
          break;

        default:
          break;
      }
    });
  }

  void _subscribe() {
    if (notifyChar == null) return;

    _notifySub = _ble.subscribeToCharacteristic(notifyChar!).listen(
          (data) {
        final msg = utf8.decode(data);
        _messages.add(msg);
      },
    );
  }

  Future<void> send(String text) async {
    if (writeChar == null || text.isEmpty) return;

    await _ble.writeCharacteristicWithResponse(
      writeChar!,
      value: utf8.encode(text),
    );
  }

  Future<void> disconnect() async {
    await _connSub?.cancel();
    await _notifySub?.cancel();
    connectedDevice = null;
    _connectionController.add(false);
  }

  void dispose() {
    _connSub?.cancel();
    _notifySub?.cancel();
    _messages.close();
    _connectionController.close();
  }
}
