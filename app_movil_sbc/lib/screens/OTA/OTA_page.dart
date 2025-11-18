import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/core/colors.dart';
import '../../common/widgets/primary_button.dart';
import '../../data/bluetooth/ble_manager.dart';
import '../../services/ota_ble_service.dart';

class OtaPage extends StatefulWidget {
  const OtaPage({super.key});

  @override
  State<OtaPage> createState() => _OtaPageState();
}

class _OtaPageState extends State<OtaPage> {
  String? _filePath;
  double _progress = 0;
  bool _uploading = false;
  String _status = "Conéctate a un dispositivo para comenzar.";

  Future<void> _selectFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['bin'],
        allowMultiple: false,
        withData: false,
        allowCompression: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _filePath = result.files.single.path!;
          _status = "Archivo seleccionado: ${result.files.single.name}";
        });
      }
    } catch (e) {
      setState(() {
        _status = "Error al seleccionar archivo: $e";
      });
    }
  }

  Future<void> _startOta() async {
    if (_filePath == null) {
      setState(() {
        _status = "⚠️ Selecciona un archivo primero.";
      });
      return;
    }

    final ble = context.read<BleManager>();
    if (ble.connectedDevice == null) {
      setState(() {
        _status = "⚠️ No hay dispositivo conectado.";
      });
      return;
    }

    final ota = OtaBleService(ble);

    try {
      final file = File(_filePath!);
      final bytes = await file.readAsBytes();

      setState(() {
        _uploading = true;
        _progress = 0;
        _status = "Iniciando OTA...";
      });

      await ota.startOta(
        bytes,
        onProgress: (p) {
          setState(() {
            _progress = p;
          });
        },
        onStatus: (s) {
          setState(() {
            _status = s;
          });
        },
      );

      setState(() {
        _uploading = false;
        _status = "✅ OTA finalizada. El ESP32 se reiniciará.";
      });
    } catch (e) {
      setState(() {
        _uploading = false;
        _status = "❌ Error durante la OTA: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleManager>();
    final isConnected = ble.connectedDevice != null;

    final theme = Theme.of(context).brightness;

    final textColor = theme == Brightness.dark
        ? AppColors.darkText
        : AppColors.lightText;
    final surfaceColor = theme == Brightness.dark
        ? AppColors.darkSurface
        : AppColors.lightSecondary;
    final primaryColor = theme == Brightness.dark
        ? AppColors.darkPrimary
        : AppColors.lightPrimary;

    return Scaffold(
      backgroundColor: theme == Brightness.dark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text("Actualización OTA"),
        automaticallyImplyLeading: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _status,
              style: TextStyle(color: textColor),
            ),
            const SizedBox(height: 24),

            // ❌ SI NO ESTÁ CONECTADO → solo mensaje
            if (!isConnected) ...{
              Text(
                "Debes conectarte a un ESP32 antes de iniciar la actualización.",
                style: TextStyle(color: textColor.withOpacity(0.6)),
              ),
            }

            // ✅ SI ESTÁ CONECTADO → mostrar botones directamente
            else ...{
              PrimaryButton(
                text: "Seleccionar archivo .bin",
                onPressed: _uploading ? null : _selectFile,
              ),
              const SizedBox(height: 12),

              if (_filePath != null)
                Text(
                  _filePath!,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.6),
                  ),
                ),

              const SizedBox(height: 24),

              PrimaryButton(
                text: _uploading ? "Enviando..." : "Iniciar actualización",
                onPressed: _uploading ? null : _startOta,
              ),

              const SizedBox(height: 24),

              if (_uploading)
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: surfaceColor,
                  color: primaryColor,
                ),
            }
          ],
        ),
      ),
    );
  }
}
