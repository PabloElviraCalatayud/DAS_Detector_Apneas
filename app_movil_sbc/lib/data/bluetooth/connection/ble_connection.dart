import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import '../ble_constants.dart';
import 'ble_packet_reassembler.dart';

class BleConnection {
  final _ble = FlutterReactiveBle();

  DiscoveredDevice? connectedDevice;

  final _connController = StreamController<DiscoveredDevice?>.broadcast();
  Stream<DiscoveredDevice?> get onConnectionChanged => _connController.stream;

  final _reassembler = BlePacketReassembler();
  Stream<Uint8List> get onRawData => _reassembler.stream;

  StreamSubscription<ConnectionStateUpdate>? _connSub;
  StreamSubscription<List<int>>? _notifySub;

  QualifiedCharacteristic? _notifyChar;
  QualifiedCharacteristic? _writeChar;

  bool get isConnected => connectedDevice != null;

  Future<Stream<DiscoveredDevice>> scan({String targetName = "DAS_ESP"}) async {
    final raw = _ble.scanForDevices(
      withServices: const [],
      scanMode: ScanMode.lowLatency,
    );

    return raw.where(
          (d) => d.name.trim().toLowerCase().contains(targetName.toLowerCase()),
    );
  }

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
          _connController.add(device);

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

          _subscribe();
          break;

        case DeviceConnectionState.disconnected:
          connectedDevice = null;
          _connController.add(null);
          await _notifySub?.cancel();
          _notifySub = null;
          _notifyChar = null;
          _writeChar = null;
          _reassembler.clear();
          break;

        default:
          break;
      }
    });
  }

  void _subscribe() {
    if (_notifyChar == null) return;

    _notifySub = _ble.subscribeToCharacteristic(_notifyChar!).listen(
          (frag) => _reassembler.addFragment(frag),
    );
  }

  Future<void> disconnect() async {
    await _connSub?.cancel();
    connectedDevice = null;
    _connController.add(null);

    await _notifySub?.cancel();
    _notifySub = null;

    _notifyChar = null;
    _writeChar = null;

    _reassembler.clear();
  }

  Future<void> send(String text) async {
    if (_writeChar == null) return;
    await _ble.writeCharacteristicWithResponse(
      _writeChar!,
      value: text.codeUnits,
    );
  }

  Future<void> write(Uint8List data) async {
    if (_writeChar == null) return;
    await _ble.writeCharacteristicWithResponse(
      _writeChar!,
      value: data,
    );
  }

  Future<int> requestMtu(int mtu) async {
    if (connectedDevice == null) {
      throw Exception("No connected device");
    }
    return _ble.requestMtu(deviceId: connectedDevice!.id, mtu: mtu);
  }

  void dispose() {
    _connController.close();
    _reassembler.dispose();
    _connSub?.cancel();
    _notifySub?.cancel();
  }
}
