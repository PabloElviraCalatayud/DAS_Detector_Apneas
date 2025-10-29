import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart'; // 👈 Asegúrate de agregar esto

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BleHomePage(),
    );
  }
}

class BleHomePage extends StatefulWidget {
  const BleHomePage({super.key});

  @override
  State<BleHomePage> createState() => _BleHomePageState();
}

class _BleHomePageState extends State<BleHomePage> {
  final flutterReactiveBle = FlutterReactiveBle();
  final List<DiscoveredDevice> _devices = [];
  Stream<DiscoveredDevice>? _scanStream;
  DiscoveredDevice? _connectedDevice;
  bool _isScanning = false;
  bool _isConnected = false;

  // ⚙️ Solicitar permisos BLE y ubicación (Android 12+)
  Future<bool> _checkPermissions() async {
    if (Platform.isAndroid) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
      ].request();

      // Verificar si todos están concedidos
      return statuses.values.every((status) => status.isGranted);
    }
    return true;
  }

  // 🔍 Escanear dispositivos BLE
  Future<void> _startScan() async {
    final hasPerms = await _checkPermissions();
    if(!mounted) return;

    if (!hasPerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permisos BLE denegados")),
      );
      return;
    }

    setState(() {
      _devices.clear();
      _isScanning = true;
    });

    _scanStream = flutterReactiveBle.scanForDevices(
      withServices: [],
      scanMode: ScanMode.lowLatency,
    );

    _scanStream!.listen((device) {
      if (device.name.isNotEmpty && !_devices.any((d) => d.id == device.id)) {
        setState(() {
          _devices.add(device);
        });
      }
    }, onError: (err) {
      debugPrint("Error de escaneo: $err");
      setState(() => _isScanning = false);
    });
  }

  // 🔗 Conectar con un dispositivo BLE
  Future<void> _connect(DiscoveredDevice device) async {
    debugPrint("Conectando a ${device.name}...");
    setState(() {
      _isScanning = false;
      _isConnected = false;
    });

    final connection = flutterReactiveBle.connectToAdvertisingDevice(
      id: device.id,
      prescanDuration: const Duration(seconds: 1),
      withServices: [],
    );

    connection.listen((update) {
      if(!mounted) return;
      switch (update.connectionState) {
        case DeviceConnectionState.connected:
          setState(() {
            _connectedDevice = device;
            _isConnected = true;
          });
          debugPrint("✅ Conectado a ${device.name}");
          break;
        case DeviceConnectionState.disconnected:
          setState(() {
            _connectedDevice = null;
            _isConnected = false;
          });
          debugPrint("🔌 Desconectado");
          break;
        default:
          break;
      }
    }, onError: (err) {
      debugPrint("Error de conexión: $err");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BLE - ESP32 NimBLE")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _isScanning ? null : _startScan,
            child: const Text("Buscar dispositivos"),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                return ListTile(
                  title: Text(device.name),
                  subtitle: Text(device.id),
                  trailing: ElevatedButton(
                    onPressed: () => _connect(device),
                    child: const Text("Conectar"),
                  ),
                );
              },
            ),
          ),
          if (_isConnected && _connectedDevice != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Conectado a: ${_connectedDevice!.name}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
