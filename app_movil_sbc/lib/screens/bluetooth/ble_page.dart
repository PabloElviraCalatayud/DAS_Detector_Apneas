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
  SensorData? _last;

  List<dynamic> _devices = [];

  @override
  void initState() {
    super.initState();

    final ble = context.read<BleManager>();
    final sensor = SensorDataModel.instance;

    // ---- CONEXIÓN BLE
    _connSub = ble.connectionStatusStream.listen((isConnected) {
      if (!mounted) return;
      setState(() => _connected = isConnected);

      if (!isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🔌 El dispositivo se ha desconectado"),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });

    // ---- DATOS DE SENSORES
    _sensorSub = sensor.sensorStream.listen((data) {
      if (!mounted) return;
      setState(() => _last = data);
    });

    if (_scanSub != null) {
      setState(() => _scanning = true);
    }
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _sensorSub?.cancel();
    super.dispose();
  }

  // ----------------------------------------
  // INICIAR ESCANEO
  // ----------------------------------------
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

  // ----------------------------------------
  // DETENER ESCANEO
  // ----------------------------------------
  void _stopScan() {
    _scanSub?.cancel();
    _scanSub = null;

    setState(() {
      _scanning = false;
    });
  }

  // ----------------------------------------
  // CONECTAR DISPOSITIVO
  // ----------------------------------------
  void _connectTo(device) async {
    final ble = context.read<BleManager>();
    await ble.connect(device);
  }

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

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _scanning ? _stopScan() : _startScan();
        },
        child: Icon(_scanning ? Icons.search_off : Icons.search),
      ),

      body: _connected
          ? _buildConnectedView(bpm, mov, hrv)
          : _buildScanView(),
    );
  }

  // -------------------------------------------------------
  // 📡 VISTA DE SCANEO (NO CONECTADO)
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
        }).toList()
      ],
    );
  }

  // -------------------------------------------------------
  // 🔥 VISTA CUANDO SÍ HAY DISPOSITIVO CONECTADO
  // -------------------------------------------------------
  Widget _buildConnectedView(int bpm, double mov, double hrv) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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

        const SizedBox(height: 20),

        // ---------------------------------------------------
        // 🔘 BOTÓN DE DESCONECTAR (SIEMPRE VISIBLE)
        // ---------------------------------------------------
        ElevatedButton.icon(
          onPressed: () async {
            await context.read<BleManager>().disconnect();
          },
          icon: const Icon(Icons.link_off),
          label: const Text("Desconectar"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}