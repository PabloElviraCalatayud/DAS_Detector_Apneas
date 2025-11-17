import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
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

  final StreamController<bool> _connectionController =
  StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  bool _shouldStayConnected = false;

  String lastMessage = "0";

  // -------------------------------------------------------------
  //  SCAN
  // -------------------------------------------------------------
  Future<Stream<DiscoveredDevice>> scan() async {
    return _ble.scanForDevices(
      withServices: const [],
      scanMode: ScanMode.lowLatency,
      requireLocationServicesEnabled: true,
    );
  }

  // -------------------------------------------------------------
  //  CONNECT
  // -------------------------------------------------------------
  Future<void> connect(DiscoveredDevice device) async {
    _shouldStayConnected = true;
    await _startConnection(device);
  }

  Future<void> _startConnection(DiscoveredDevice device) async {
    print("🔗 Attempting connection to ${device.id}");

    _connSub = _ble
        .connectToDevice(
      id: device.id,
      connectionTimeout: const Duration(seconds: 10),
    )
        .listen((update) async {
      switch (update.connectionState) {
        case DeviceConnectionState.connected:
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

          // Request larger MTU if needed (optional)
          try {
            final negotiated = await _ble.requestMtu(deviceId: device.id, mtu: 200);
            print("📐 MTU negotiated: $negotiated");
          } catch (e) {
            print("⚠️ MTU request failed: $e");
          }

          _subscribe();
          break;

        case DeviceConnectionState.disconnected:
          print("⚠️ Device disconnected");
          connectedDevice = null;
          _connectionController.add(false);

          if (_shouldStayConnected) {
            print("♻️ Reconnecting...");
            await Future.delayed(const Duration(seconds: 2));
            await _startConnection(device);
          }
          break;

        default:
          break;
      }
    });
  }

  // -------------------------------------------------------------
  //  SUBSCRIBE TO BINARY NOTIFICATIONS
  // -------------------------------------------------------------
  void _subscribe() {
    if (notifyChar == null) return;

    print("📡 Subscribing to notifications...");

    _notifySub = _ble.subscribeToCharacteristic(notifyChar!).listen(
          (data) {
        print("📩 Raw packet (${data.length} bytes): $data");

        final decoded = decodePacket(Uint8List.fromList(data));

        print("📦 Decoded: $decoded");

        lastMessage = jsonEncode(decoded);
        _messages.add(jsonEncode(decoded));
        notifyListeners();
      },
      onError: (e) {
        print("❌ Notification error: $e");
      },
    );
  }

  // -------------------------------------------------------------
  //  PACKET DECODER (compact format - Option A)
  // -------------------------------------------------------------
  Map<String, dynamic> decodePacket(Uint8List p) {
    final bd = ByteData.sublistView(p);
    int offset = 0;

    if (p.length < 11) {
      return {"error": "packet too short", "len": p.length};
    }

    // flags (top two bits describe type)
    final flags = bd.getUint8(offset);
    offset += 1;

    // timestamp uint64 little-endian
    // ByteData does not have getUint64 with Endian in some platforms, so read as two uint32
    final low = bd.getUint32(offset, Endian.little);
    final high = bd.getUint32(offset + 4, Endian.little);
    final timestamp = (high << 32) | low;
    offset += 8;

    // counts
    final countImu = bd.getUint8(offset); offset += 1;
    final countPulse = bd.getUint8(offset); offset += 1;

    final samples = <Map<String, dynamic>>[];

    for (int i = 0; i < countImu; i++) {
      if (offset + 12 > p.length) break;
      final ax = bd.getInt16(offset, Endian.little); offset += 2;
      final ay = bd.getInt16(offset, Endian.little); offset += 2;
      final az = bd.getInt16(offset, Endian.little); offset += 2;
      final gx = bd.getInt16(offset, Endian.little); offset += 2;
      final gy = bd.getInt16(offset, Endian.little); offset += 2;
      final gz = bd.getInt16(offset, Endian.little); offset += 2;

      samples.add({
        "ax": ax / 100.0,
        "ay": ay / 100.0,
        "az": az / 100.0,
        "gx": gx / 100.0,
        "gy": gy / 100.0,
        "gz": gz / 100.0,
      });
    }

    final pulses = <int>[];
    for (int i = 0; i < countPulse; i++) {
      if (offset + 2 > p.length) break;
      final pulse = bd.getUint16(offset, Endian.little); offset += 2;
      pulses.add(pulse);
    }

    return {
      "flags": flags,
      "timestamp": timestamp,
      "imu_samples": countImu,
      "pulse_samples": countPulse,
      "samples": samples,
      "pulses": pulses,
    };
  }

  // -------------------------------------------------------------
  //  WRITE TEXT
  // -------------------------------------------------------------
  Future<void> send(String text) async {
    if (writeChar == null || text.isEmpty) return;
    await _ble.writeCharacteristicWithResponse(writeChar!, value: text.codeUnits);
  }

  // -------------------------------------------------------------
  //  WRITE BINARY
  // -------------------------------------------------------------
  Future<void> write(Uint8List data) async {
    if (writeChar == null) return;
    try {
      await _ble.writeCharacteristicWithResponse(writeChar!, value: data);
      print("📤 Enviado ${data.length} bytes");
    } catch (e) {
      print("❌ Error enviando datos binarios: $e");
      rethrow;
    }
  }

  // -------------------------------------------------------------
  //  MTU (ANDROID)
  // -------------------------------------------------------------
  Future<int> requestMtu(int mtu) async {
    if (connectedDevice == null) throw Exception("No device connected");
    try {
      final negotiatedMtu =
      await _ble.requestMtu(deviceId: connectedDevice!.id, mtu: mtu);
      print("📐 MTU negotiated: $negotiatedMtu");
      return negotiatedMtu;
    } catch (e) {
      print("❌ MTU request failed: $e");
      rethrow;
    }
  }

  // -------------------------------------------------------------
  //  DISCONNECT
  // -------------------------------------------------------------
  Future<void> disconnect() async {
    _shouldStayConnected = false;
    await _connSub?.cancel();
    await _notifySub?.cancel();
    connectedDevice = null;
    _connectionController.add(false);
  }

  @override
  void dispose() {
    _shouldStayConnected = false;
    _connSub?.cancel();
    _notifySub?.cancel();
    _messages.close();
    _connectionController.close();
    super.dispose();
  }
}
