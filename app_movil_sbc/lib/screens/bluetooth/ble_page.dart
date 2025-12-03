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

    // 💥 Restaurar estado si vuelves conectado desde Dashboard
    _connected = ble.isConnected;
    if (_connected) {
      _showConnectedBanner = true;
    }

    // 🔗 Conexión BLE
    _connSub = ble.connectionStatusStream.listen((isConnected) {
      if (!mounted) return;

      setState(() {
        _connected = isConnected;

        if (isConnected) {
          _showConnectedBanner = true;
        } else {
          _showConnectedBanner = false;
        }
      });

      if (!isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🔌 El dispositivo se ha desconectado"),
            duration: Duration(seconds: 2),
          ),
        );
      }
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

  // ------------------------------------------------------------
  // 🔍 ESCANEO
  // ------------------------------------------------------------
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
    final ble = context.read<BleManager>();
    await ble.connect(device);
    setState(() => _showConnectedBanner = true);
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final bpm = _last?.heartRate ?? 0;
    final mov = _last?.movementIndex ?? 0;
    final hrv = _last?.hrv ?? 0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, "/home");
            }
          },
        ),
        title: const Text("Dispositivo BLE"),
        actions: [
          Icon(
            _connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            color: _connected ? Colors.green : Colors.red,
          )
        ],
      ),

      floatingActionButton: (!_connected)
          ? FloatingActionButton(
        onPressed: () {
          _scanning ? _stopScan() : _startScan();
        },
        child: Icon(_scanning ? Icons.search_off : Icons.search),
      )
          : null,

      body: _connected
          ? _buildConnectedView(bpm, mov, hrv)
          : _buildScanView(),
    );
  }

  // ------------------------------------------------------------
  // 📡 Vista SCANEO
  // ------------------------------------------------------------
  Widget _buildScanView() {
    final ble = context.read<BleManager>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_showConnectedBanner && ble.connectedDeviceName != null)
          _connectedBanner(),

        const Text(
          "Dispositivos encontrados",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        if (_scanning)
          const Center(child: CircularProgressIndicator()),

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
        }),
      ],
    );
  }

  // ------------------------------------------------------------
  // 🔥 Vista SENSORES
  // ------------------------------------------------------------
  Widget _buildConnectedView(int bpm, double mov, double hrv) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _connectedBanner(),
        const SizedBox(height: 12),

        Card(
          child: ListTile(
            title: const Text("Estado"),
            subtitle: Text(_connected ? "Conectado" : "Desconectado"),
          ),
        ),
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

  // ------------------------------------------------------------
  // 🔵 BANNER: “Conectado a X”
  // ------------------------------------------------------------
  Widget _connectedBanner() {
    final ble = context.read<BleManager>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,                // ✔ más legible
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              "Conectado a:\n${ble.connectedDeviceName ?? "Dispositivo"}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,              // ✔ mayor contraste
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await ble.disconnect();
              setState(() {
                _showConnectedBanner = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text("Desconectar"),
          ),
        ],
      ),
    );
  }
}