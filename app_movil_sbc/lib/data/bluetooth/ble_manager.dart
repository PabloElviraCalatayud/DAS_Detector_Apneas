import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'ble_constants.dart';

class BleManager extends ChangeNotifier {
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

  bool _shouldStayConnected = false;

  // ✅ almacena el último mensaje
  String lastMessage = "0";

  Future<Stream<DiscoveredDevice>> scan() async {
    return _ble.scanForDevices(
      withServices: const [],
      scanMode: ScanMode.lowLatency,
      requireLocationServicesEnabled: true,
    );
  }

  Future<void> connect(DiscoveredDevice device) async {
    _shouldStayConnected = true;
    await _startConnection(device);
  }

  Future<void> _startConnection(DiscoveredDevice device) async {
    print("🔗 Attempting connection to ${device.id}");

    _connSub = _ble.connectToDevice(
      id: device.id,
      connectionTimeout: const Duration(seconds: 10),
    ).listen((update) async {
      switch (update.connectionState) {
        case DeviceConnectionState.connected: {
          print("✅ Connected to ${device.id}");
          connectedDevice = device;
          _connectionController.add(true);

          print("🔍 Discovering services...");
          await _ble.discoverAllServices(device.id);

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
        } break;

        case DeviceConnectionState.disconnected: {
          print("⚠️ Device disconnected");

          connectedDevice = null;
          _connectionController.add(false);

          if (_shouldStayConnected) {
            print("♻️ Reconnecting...");
            await Future.delayed(const Duration(seconds: 2));
            await _startConnection(device);
          }
        } break;

        default:
          break;
      }
    });
  }

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

        // ✅ Guardar último mensaje + notificar UI
        lastMessage = msg;
        _messages.add(msg);
        notifyListeners();
      },
      onError: (e) {
        print("❌ Notification error: $e");
      },
    );
  }

  Future<void> send(String text) async {
    if (writeChar == null || text.isEmpty) return;

    print("📤 Sending: $text");
    await _ble.writeCharacteristicWithResponse(
      writeChar!,
      value: utf8.encode(text),
    );
  }

  Future<void> disconnect() async {
    print("🔌 Manual disconnect");

    _shouldStayConnected = false;

    await _connSub?.cancel();
    await _notifySub?.cancel();

    connectedDevice = null;
    _connectionController.add(false);
  }

  @override
  void dispose() {
    super.dispose();
    _shouldStayConnected = false;
    _connSub?.cancel();
    _notifySub?.cancel();
    _messages.close();
    _connectionController.close();
  }
}
