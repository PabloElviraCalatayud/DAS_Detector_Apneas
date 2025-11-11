import 'dart:io';
import 'dart:typed_data';
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
  String _status = "Esperando archivo...";

  Future<void> _selectFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['bin'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _filePath = result.files.single.path;
        _status = "Archivo seleccionado: ${result.files.single.name}";
      });
    }
  }

  Future<void> _startOta() async {
    if (_filePath == null) {
      setState(() => _status = "⚠️ Selecciona un archivo primero.");
      return;
    }

    final ble = context.read<BleManager>();
    final ota = OtaBleService(ble);

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
        setState(() => _progress = p);
      },
      onStatus: (s) {
        setState(() => _status = s);
      },
    );

    setState(() {
      _uploading = false;
      _status = "✅ OTA finalizada, el ESP32 se reiniciará.";
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: theme == Brightness.dark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text("Actualización OTA"),
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
              style: TextStyle(
                color: theme == Brightness.dark
                    ? AppColors.darkText
                    : AppColors.lightText,
              ),
            ),
            const SizedBox(height: 24),
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
                  color: theme == Brightness.dark
                      ? AppColors.darkSecondary
                      : AppColors.lightSecondary,
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
                backgroundColor: theme == Brightness.dark
                    ? AppColors.darkSurface
                    : AppColors.lightSecondary,
                color: theme == Brightness.dark
                    ? AppColors.darkPrimary
                    : AppColors.lightPrimary,
              ),
          ],
        ),
      ),
    );
  }
}
