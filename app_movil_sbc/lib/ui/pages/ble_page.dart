import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import '../../data/ble_manager.dart';
import '../widgets/device_tile.dart';

class BlePage extends StatefulWidget {
  const BlePage({super.key});

  @override
  State<BlePage> createState() => _BlePageState();
}

class _BlePageState extends State<BlePage> {
  final BleManager _ble = BleManager();
  final TextEditingController _controller = TextEditingController();
  final List<DiscoveredDevice> _devices = [];

  String _status = "Desconectado";
  String _lastMessage = "";
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _ble.messages.listen((msg) {
      setState(() => _lastMessage = msg);
    });
  }

  Future<void> _scan() async {
    setState(() {
      _isScanning = true;
      _status = "Escaneando...";
      _devices.clear();
    });
    await _ble.scan((device) {
      setState(() => _devices.add(device));
    });
    setState(() => _isScanning = false);
  }

  Future<void> _connect(DiscoveredDevice device) async {
    await _ble.connect(device, (status) => setState(() => _status = status));
  }

  Future<void> _disconnect() async {
    await _ble.disconnect();
    setState(() => _status = "Desconectado");
  }

  Future<void> _send() async {
    await _ble.send(_controller.text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final connected = _ble.connectedDevice != null;

    return Scaffold(
      appBar: AppBar(title: const Text("BLE Bidireccional ESP32")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Estado: $_status", style: const TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isScanning ? null : _scan,
                    child: Text(_isScanning ? "Buscando..." : "Buscar dispositivos"),
                  ),
                ),
                const SizedBox(width: 8),
                if (connected)
                  ElevatedButton(
                    onPressed: _disconnect,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text("Desconectar"),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: _devices.length,
                itemBuilder: (context, i) {
                  final d = _devices[i];
                  return DeviceTile(
                    device: d,
                    isConnected: _ble.connectedDevice?.id == d.id,
                    onConnect: () => _connect(d),
                  );
                },
              ),
            ),
            if (connected) ...[
              const Divider(),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(labelText: "Enviar texto al ESP32"),
              ),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _send, child: const Text("Enviar")),
              const SizedBox(height: 16),
              Text("📬 Último mensaje: $_lastMessage",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ],
        ),
      ),
    );
  }
}
