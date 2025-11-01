import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import '../../common/core/permissions.dart';
import '../../data/bluetooth/ble_manager.dart';


class BlePage extends StatefulWidget {
  const BlePage({super.key});

  @override
  State<BlePage> createState() => _BlePageState();
}

class _BlePageState extends State<BlePage> {
  final BleManager _ble = BleManager();
  StreamSubscription<DiscoveredDevice>? _scanSub;
  final List<DiscoveredDevice> _devices = [];

  bool _isScanning = false;
  String _status = "Desconectado";
  String _lastMessage = "";

  @override
  void initState() {
    super.initState();

    _ble.messages.listen((msg) {
      setState(() {
        _lastMessage = msg;
      });
    });

    _ble.connectionStream.listen((connected) {
      setState(() {
        _status = connected ? "Conectado" : "Desconectado";
      });
    });
  }

  Future<void> _scan() async {
    await PermissionService.requestBlePermissions();

    setState(() {
      _isScanning = true;
      _devices.clear();
      _status = "Escaneando...";
    });

    final stream = await _ble.scan();

    _scanSub = stream.listen((device) {
      if (device.name.isNotEmpty && !_devices.any((d) => d.id == device.id)) {
        setState(() {
          _devices.add(device);
        });
      }
    });

  }

  Future<void> _stopScan() async {
    await _scanSub?.cancel();
    setState(() {
      _isScanning = false;
      _status = "Escaneo detenido";
    });
  }

  Future<void> _connect(DiscoveredDevice device) async {
    setState(() {
      _status = "Conectando...";
    });
    await _ble.connect(device);
  }

  Future<void> _disconnect() async {
    await _ble.disconnect();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _ble.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connected = _ble.connectedDevice != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Conexión Bluetooth"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Estado: $_status", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isScanning ? null : _scan,
                    child: Text(_isScanning ? "Buscando..." : "Buscar dispositivos"),
                  ),
                ),
                const SizedBox(width: 10),

                if (_isScanning)
                  ElevatedButton(
                    onPressed: _stopScan,
                    child: const Text("Detener"),
                  ),

                if (! _isScanning && connected)
                  ElevatedButton(
                    onPressed: _disconnect,
                    child: const Text("Desconectar"),
                  ),
              ],
            ),

            const SizedBox(height: 18),

            Expanded(
              child: ListView.builder(
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  final d = _devices[index];

                  return Card(
                    child: ListTile(
                      title: Text(d.name),
                      subtitle: Text(d.id),
                      trailing: _ble.connectedDevice?.id == d.id
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.bluetooth),
                      onTap: () => _connect(d),
                    ),
                  );
                },
              ),
            ),

            if (connected) ...[
              const Divider(),
              Text("Último mensaje: $_lastMessage"),
            ],
          ],
        ),
      ),
    );
  }
}
