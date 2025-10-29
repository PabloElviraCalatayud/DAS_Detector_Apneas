import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class DeviceTile extends StatelessWidget {
  final DiscoveredDevice device;
  final bool isConnected;
  final VoidCallback onConnect;

  const DeviceTile({
    super.key,
    required this.device,
    required this.isConnected,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(device.name),
        subtitle: Text(device.id),
        trailing: ElevatedButton(
          onPressed: isConnected ? null : onConnect,
          child: Text(isConnected ? "Conectado" : "Conectar"),
        ),
      ),
    );
  }
}
