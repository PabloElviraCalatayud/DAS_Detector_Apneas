import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../codec/ble_decoder.dart';
import '../codec/ble_packet.dart';
import '../connection/ble_connection.dart';
import '../manager/ble_permissions.dart';
import '../../models/sensor_data_model.dart';

class BleManager extends ChangeNotifier {
  // --------------------------------------------------
  // SINGLETON
  // --------------------------------------------------
  BleManager._internal() {
    _bindPacketPipeline(); // 🔴 CLAVE: iniciar pipeline al arrancar la app
  }

  static final BleManager instance = BleManager._internal();

  // --------------------------------------------------
  // DEPENDENCIAS
  // --------------------------------------------------
  final BleConnection _connection = BleConnection();

  final List<DiscoveredDevice> devices = [];

  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<Uint8List>? _rawSub;
  StreamSubscription<DiscoveredDevice?>? _connChangedSub;

  final StreamController<BlePacket> _packetController =
  StreamController<BlePacket>.broadcast();

  Stream<BlePacket> get packetStream => _packetController.stream;

  // --------------------------------------------------
  // GETTERS
  // --------------------------------------------------
  bool get isConnected => _connection.isConnected;
  String? get connectedDeviceName => _connection.connectedDevice?.name;

  // --------------------------------------------------
  // 🔗 PIPELINE GLOBAL (BLE → SensorDataModel)
  // --------------------------------------------------
  void _bindPacketPipeline() {
    packetStream.listen((packet) {
      // 🔥 AQUÍ ESTÁ LA MAGIA
      SensorDataModel.instance.updateFromPacket(packet);
    });
  }

  // --------------------------------------------------
  // MTU
  // --------------------------------------------------
  Future<int> requestMtu(int size) async {
    return await _connection.requestMtu(size);
  }

  // --------------------------------------------------
  // SCAN (SIN CAMBIOS)
  // --------------------------------------------------
  Future<void> startScan() async {
    final ok = await BlePermissions.ensureBlePermissions();
    if (!ok) return;

    devices.clear();
    notifyListeners();

    final raw = await _connection.scan();
    _scanSub = raw.listen((device) {
      if (!devices.any((d) => d.id == device.id)) {
        devices.add(device);
        notifyListeners();
      }
    });
  }

  Future<void> stopScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
  }

  // --------------------------------------------------
  // CONNECT (SIN CAMBIOS)
  // --------------------------------------------------
  Future<void> connect(DiscoveredDevice device) async {
    await stopScan();
    await _rawSub?.cancel();
    await _connChangedSub?.cancel();

    await _connection.connect(device);

    _rawSub = _connection.onRawData.listen((bytes) {
      final pkt = BleDecoder.decodeCompact(bytes);
      if (pkt != null) {
        _packetController.add(pkt);
      }
    });

    _connChangedSub = _connection.onConnectionChanged.listen((_) {
      notifyListeners();
    });
  }

  // --------------------------------------------------
  // DISCONNECT (SIN CAMBIOS)
  // --------------------------------------------------
  Future<void> disconnect() async {
    await _rawSub?.cancel();
    _rawSub = null;

    await _connChangedSub?.cancel();
    _connChangedSub = null;

    await _connection.disconnect();
    notifyListeners();
  }

  // --------------------------------------------------
  // WRITE
  // --------------------------------------------------
  Future<void> sendText(String text) async {
    await _connection.send(text);
  }

  Future<void> writeBinary(Uint8List data) async {
    await _connection.write(data);
  }

  // --------------------------------------------------
  // CLEANUP
  // --------------------------------------------------
  @override
  void dispose() {
    _packetController.close();
    _scanSub?.cancel();
    _rawSub?.cancel();
    _connChangedSub?.cancel();
    _connection.dispose();
    super.dispose();
  }
}
