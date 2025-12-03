import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/bluetooth/ble_manager.dart';
import '../../data/models/sensor_data.dart';
import '../../data/models/sensor_data_model.dart';

class BlePage extends StatefulWidget {
  const BlePage({super.key});

  @override
  State<BlePage> createState() => _BlePageState();
}

class _BlePageState extends State<BlePage> {
  StreamSubscription<bool>? _connSub;
  StreamSubscription<SensorData>? _sensorSub;
  StreamSubscription? _scanSub;

  bool _connected = false;
  bool _scanning = false;
  bool _showConnectedBanner = false;

  SensorData? _last;
  List<dynamic> _devices = [];

  @override
  void initState() {
    super.initState();

    final ble = context.read<BleManager>();
    final sensor = SensorDataModel.instance;

    // 🔗 Estado de conexión BLE
    _connSub = ble.connectionStatusStream.listen((isConnected) {
      if (!mounted) return;
      setState(() {
        _connected = isConnected;
        if (isConnected) _showConnectedBanner = true;
      });
    });

    // 📡 Datos sensores
    _sensorSub = sensor.sensorStream.listen((data) {
      if (!mounted) return;
      setState(() => _last = data);
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _sensorSub?.cancel();
    _scanSub?.cancel();
    super.dispose();
  }

  // ------------------------------------------------
  // 🔍 INICIO ESCANEO
  // ------------------------------------------------
  void _startScan() {
    final ble = context.read<BleManager>();

    _scanSub?.cancel();

    setState(() {
      _devices.clear();
      _scanning = true;
    });

    _scanSub = ble.scan().listen((device) {
      if (!_devices.any((d) => d.id == device.id)) {
        setState(() => _devices.add(device));
      }
    }, onDone: () {
      setState(() => _scanning = false);
    });
  }

  void _stopScan() {
    _scanSub?.cancel();
    _scanSub = null;
    setState(() => _scanning = false);
  }

  void _connectTo(device) async {
    await context.read<BleManager>().connect(device);
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleManager>();
    final bpm = _last?.heartRate ?? 0;
    final mov = _last?.movementIndex ?? 0;
    final hrv = _last?.hrv ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dispositivo BLE"),
      ),
      floatingActionButton: !_connected
          ? FloatingActionButton(
        onPressed: () => _scanning ? _stopScan() : _startScan(),
        child: Icon(_scanning ? Icons.search_off : Icons.search),
      )
          : null,
      body: _connected
          ? Column(
        children: [
          // 🔵 BANNER DE CONEXIÓN
          if (_showConnectedBanner)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              color: Colors.blue.shade700,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Conectado a ${ble.connectedDevice?.name ?? 'desconocido'}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await ble.disconnect();
                      setState(() {
                        _showConnectedBanner = false;
                      });
                    },
                    child: const Text(
                      "Desconectar",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(child: _buildSensorView(bpm, mov, hrv)),

          const SizedBox(height: 10),

          // 🔘 BOTÓN A OTA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/ota');
              },
              icon: const Icon(Icons.update),
              label: const Text("Actualizar Firmware (OTA)"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      )
          : _buildScanView(),
    );
  }

  // -------------------------------------------------------
  // 🔍 VISTA DE ESCANEO
  // -------------------------------------------------------
  Widget _buildScanView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "Dispositivos encontrados",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (_scanning) const Center(child: CircularProgressIndicator()),
        ..._devices.map((d) {
          return Card(
            child: ListTile(
              title: Text(d.name.isNotEmpty ? d.name : "Sin nombre"),
              subtitle: Text(d.id),
              trailing: ElevatedButton(
                onPressed: () => _connectTo(d),
                child: const Text("Conectar"),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  // -------------------------------------------------------
  // 🔥 VISTA DE SENSORES
  // -------------------------------------------------------
  Widget _buildSensorView(int bpm, double mov, double hrv) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            title: const Text("Heart Rate"),
            subtitle: Text("$bpm BPM"),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text("Movimiento"),
            subtitle: Text(mov.toStringAsFixed(2)),
          ),
        ),
        Card(
          child: ListTile(
            title: const Text("HRV"),
            subtitle: Text(hrv.toStringAsFixed(2)),
          ),
        ),
      ],
    );
  }
}
