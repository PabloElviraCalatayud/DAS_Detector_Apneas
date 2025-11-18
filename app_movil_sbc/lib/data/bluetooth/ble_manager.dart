import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../models/sensor_data_model.dart';
import 'ble_constants.dart';
import 'ble_decoder.dart';
import 'ble_packet.dart';

class BleManager extends ChangeNotifier {
  // Singleton
  BleManager._internal();
  static final BleManager instance = BleManager._internal();

  final FlutterReactiveBle _ble = FlutterReactiveBle();

  // Device info
  DiscoveredDevice? connectedDevice;
  StreamSubscription<ConnectionStateUpdate>? _connSub;
  StreamSubscription<List<int>>? _notifySub;

  // Scan controller
  StreamController<DiscoveredDevice>? _scanController;

  // Raw packet stream
  final StreamController<BlePacket> _rawPacketController =
  StreamController<BlePacket>.broadcast();
  Stream<BlePacket> get rawPacketStream => _rawPacketController.stream;

  // Connection status stream
  final StreamController<bool> _connectionStatusController =
  StreamController<bool>.broadcast();
  Stream<bool> get connectionStatusStream =>
      _connectionStatusController.stream;

  // Heartbeat tracking
  int _latestHeartRate = 0;
  int get latestHeartRate => _latestHeartRate;

  bool get isConnected => connectedDevice != null;

  // ---------------------------------------------------------
  // SCAN
  // ---------------------------------------------------------
  Stream<DiscoveredDevice> scan() {
    try {
      _ble.deinitialize();
    } catch (_) {}

    _scanController?.close();
    _scanController = StreamController<DiscoveredDevice>.broadcast();

    _ble
        .scanForDevices(
      withServices: [],
      scanMode: ScanMode.lowLatency,
    )
        .listen(
          (device) {
        if (device.name.isNotEmpty && device.name.startsWith("ESP")) {
          _scanController?.add(device);
        }
      },
      onError: (e) => _scanController?.addError(e),
    );

    return _scanController!.stream;
  }

  // ---------------------------------------------------------
  // CONNECT
  // ---------------------------------------------------------
  Future<void> connect(DiscoveredDevice device) async {
    await disconnect();

    connectedDevice = device;

    _connSub = _ble
        .connectToDevice(
      id: device.id,
      connectionTimeout: const Duration(seconds: 6),
    )
        .listen((update) {
      if (update.connectionState == DeviceConnectionState.connected) {
        _connectionStatusController.add(true);
        _subscribeNotifications();
        notifyListeners();
      }

      if (update.connectionState == DeviceConnectionState.disconnected) {
        connectedDevice = null;
        _connectionStatusController.add(false);
        notifyListeners();
      }
    });
  }

  // ---------------------------------------------------------
  // DISCONNECT
  // ---------------------------------------------------------
  Future<void> disconnect() async {
    await _notifySub?.cancel();
    await _connSub?.cancel();

    _notifySub = null;
    _connSub = null;
    connectedDevice = null;

    _connectionStatusController.add(false);

    notifyListeners();
  }

  // ---------------------------------------------------------
  // NOTIFY SUBSCRIPTION
  // ---------------------------------------------------------
  void _subscribeNotifications() {
    if (connectedDevice == null) return;

    final characteristic = QualifiedCharacteristic(
      serviceId: BleConstants.serviceUuid,
      characteristicId: BleConstants.notifyCharacteristicUuid,
      deviceId: connectedDevice!.id,
    );

    _notifySub = _ble.subscribeToCharacteristic(characteristic).listen(
          (data) {
        _handleIncoming(Uint8List.fromList(data));
      },
    );
  }

  // ---------------------------------------------------------
  // PACKET PROCESSING
  // ---------------------------------------------------------
  void _handleIncoming(Uint8List bytes) {
    final packet = decodePacketCompact(bytes);
    if (packet == null) return;

    _rawPacketController.add(packet);

    final model = SensorDataModel.instance;
    model.process(packet);

    final d = model.lastData;
    if (d != null) {
      _latestHeartRate = d.heartRate;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------
  // BLE WRITE (OTA SUPPORT)
  // ---------------------------------------------------------
  Future<void> write(Uint8List data) async {
    if (connectedDevice == null) {
      throw Exception("Device not connected");
    }

    final characteristic = QualifiedCharacteristic(
      serviceId: BleConstants.serviceUuid,
      characteristicId: BleConstants.writeCharacteristicUuid,
      deviceId: connectedDevice!.id,
    );

    await _ble.writeCharacteristicWithResponse(characteristic, value: data);
  }

  Future<void> send(String text) async {
    await write(Uint8List.fromList(text.codeUnits));
  }

  // ---------------------------------------------------------
  // MTU REQUEST (OTA)
  // ---------------------------------------------------------
  Future<int> requestMtu(int size) async {
    if (connectedDevice == null) {
      throw Exception("Device not connected");
    }

    return await _ble.requestMtu(
      deviceId: connectedDevice!.id,
      mtu: size,
    );
  }

  // ---------------------------------------------------------
  // CLEANUP
  // ---------------------------------------------------------
  @override
  void dispose() {
    _scanController?.close();
    _rawPacketController.close();
    _connectionStatusController.close();
    disconnect();
    super.dispose();
  }
}
