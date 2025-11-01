import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';

import '../../common/core/permissions.dart';
import '../../common/widgets/primary_button.dart';
import '../../data/bluetooth/ble_manager.dart';
import '../../common/core/colors.dart';

class BlePage extends StatefulWidget {
  const BlePage({super.key});

  @override
  State<BlePage> createState() => _BlePageState();
}

class _BlePageState extends State<BlePage> {
  StreamSubscription<DiscoveredDevice>? _scanSub;
  final List<DiscoveredDevice> _devices = [];

  bool _isScanning = false;
  String _status = "Desconectado";
  String _lastMessage = "";

  @override
  void initState() {
    super.initState();

    final ble = context.read<BleManager>();

    ble.messages.listen((msg) {
      if (!mounted) return;
      setState(() {
        _lastMessage = msg;
      });
    });

    ble.connectionStream.listen((connected) {
      if (!mounted) return;
      setState(() {
        _status = connected ? "Conectado" : "Desconectado";
      });
    });
  }

  Future<void> _scan() async {
    final ble = context.read<BleManager>();
    await PermissionService.requestBlePermissions();

    setState(() {
      _isScanning = true;
      _devices.clear();
      _status = "Buscando dispositivos...";
    });

    final stream = await ble.scan();

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
    final ble = context.read<BleManager>();

    setState(() {
      _status = "Conectando...";
    });

    await ble.connect(device);

    // ✅ añadir dispositivo manual si no está listado
    if (!_devices.any((d) => d.id == device.id)) {
      setState(() {
        _devices.add(
          DiscoveredDevice(
            id: device.id,
            name: device.name,
            serviceData: const {},
            manufacturerData: Uint8List(0), // ✅ FIX
            rssi: 0,
            serviceUuids: const [],
          ),
        );
      });
    }
  }

  Future<void> _disconnect() async {
    final ble = context.read<BleManager>();
    await ble.disconnect();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleManager>();
    final connected = ble.connectedDevice != null;
    final theme = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: theme == Brightness.dark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text("Conexión Bluetooth"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Estado: $_status",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme == Brightness.dark
                    ? AppColors.darkText
                    : AppColors.lightText,
              ),
            ),
            const SizedBox(height: 14),

            // ✅ Botón de scan o stop reutilizando tu PrimaryButton
            if (!_isScanning)
              PrimaryButton(
                text: "Buscar dispositivos",
                onPressed: _scan,
              )
            else
              PrimaryButton(
                text: "Buscando...",
                onPressed: _stopScan,
              ),

            const SizedBox(height: 14),

            Expanded(
              child: ListView(
                children: [
                  // ✅ Mostrar SIEMPRE el conectado
                  if (ble.connectedDevice != null)
                    Card(
                      color: theme == Brightness.dark
                          ? AppColors.darkSurface
                          : AppColors.lightSecondary,
                      child: ListTile(
                        title: Text(
                          ble.connectedDevice!.name.isNotEmpty
                              ? ble.connectedDevice!.name
                              : "Dispositivo conectado",
                        ),
                        subtitle: Text(ble.connectedDevice!.id),
                        trailing: Icon(Icons.check_circle,
                            color: Colors.green.shade600),
                        onTap: _disconnect, // ✅ permite desconectar
                      ),
                    ),

                  // ✅ Mostrar lista de dispositivos encontrados
                  ..._devices.map((d) {
                    final isConnected = ble.connectedDevice?.id == d.id;

                    return Card(
                      color: theme == Brightness.dark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      child: ListTile(
                        title: Text(d.name),
                        subtitle: Text(d.id),
                        trailing: Icon(
                          Icons.bluetooth,
                          color: isConnected ? Colors.green : null,
                        ),
                        onTap: () => _connect(d),
                      ),
                    );
                  }),
                ],
              ),
            ),

            if (connected) ...[
              const Divider(),
              Text(
                "Último mensaje: $_lastMessage",
                style: TextStyle(
                  color: theme == Brightness.dark
                      ? AppColors.darkText
                      : AppColors.lightText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
