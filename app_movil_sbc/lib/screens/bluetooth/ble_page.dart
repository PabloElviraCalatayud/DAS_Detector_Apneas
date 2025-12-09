import 'package:flutter/material.dart';
import '../../data/bluetooth/ble_manager.dart';

class BLEPage extends StatefulWidget {
  const BLEPage({super.key});

  @override
  State<BLEPage> createState() => _BLEPageState();
}

class _BLEPageState extends State<BLEPage> {
  final BleManager ble = BleManager.instance;
  bool scanning = false;

  @override
  void initState() {
    super.initState();
    ble.addListener(_onBleUpdate);
  }

  @override
  void dispose() {
    ble.removeListener(_onBleUpdate);
    super.dispose();
  }

  void _onBleUpdate() {
    setState(() {});
  }

  void startScan() async {
    setState(() {
      scanning = true;
    });

    await ble.startScan();

    setState(() {
      scanning = false;
    });
  }

  void stopScan() async {
    await ble.stopScan();
    setState(() {
      scanning = false;
    });
  }

  void connectToDevice(int index) {
    final device = ble.devices[index];
    ble.connect(device);
  }

  void disconnectFromDevice() {
    ble.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = ble.isConnected;
    final connected = ble.connectedDeviceName ?? "Unknown";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dispositivos BLE"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          // -----------------------------
          //  Scan / Stop buttons
          // -----------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text("Scan"),
                onPressed: scanning ? null : startScan,
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.stop),
                label: const Text("Stop"),
                onPressed: scanning ? stopScan : null,
              )
            ],
          ),

          const SizedBox(height: 16),

          // -----------------------------
          // Lista de dispositivos encontrados
          // -----------------------------
          Expanded(
            child: ble.devices.isEmpty
                ? const Center(
              child: Text(
                "No se han encontrado dispositivos",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: ble.devices.length,
              itemBuilder: (context, i) {
                final d = ble.devices[i];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.bluetooth, color: Colors.blue),
                    title: Text(d.name.isEmpty ? "Dispositivo sin nombre" : d.name),
                    subtitle: Text(d.id),
                    trailing: ElevatedButton.icon(
                      icon: const Icon(Icons.link),
                      label: const Text("Connect"),
                      onPressed: () => connectToDevice(i),
                    ),
                  ),
                );
              },
            ),
          ),

          // -----------------------------
          // Zona de dispositivo conectado
          // -----------------------------
          if (isConnected)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                border: const Border(
                  top: BorderSide(color: Colors.green, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Conectado a:",
                          style: TextStyle(fontSize: 14, color: Colors.green),
                        ),
                        Text(
                          connected,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                  ),

                  // -----------------------------
                  // Botón OTA
                  // -----------------------------
                  IconButton(
                    icon: const Icon(Icons.system_update_alt, color: Colors.blue),
                    tooltip: "Actualizar firmware",
                    onPressed: () {
                      Navigator.pushNamed(context, "/ota");
                    },
                  ),

                  // -----------------------------
                  // Botón desconectar
                  // -----------------------------
                  IconButton(
                    icon: const Icon(Icons.link_off, color: Colors.red),
                    tooltip: "Desconectar",
                    onPressed: disconnectFromDevice,
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }
}
