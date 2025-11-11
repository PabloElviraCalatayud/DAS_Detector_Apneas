import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class OtaBleService {
  final FlutterReactiveBle _ble;
  final QualifiedCharacteristic otaCharacteristic;

  OtaBleService(this._ble, this.otaCharacteristic);

  /// Envía un comando de texto (BEGIN o END)
  Future<void> sendCommand(String command) async {
    final data = Uint8List.fromList(command.codeUnits);
    await _ble.writeCharacteristicWithResponse(otaCharacteristic, value: data);
  }

  /// Envía un binario fragmentado
  Future<void> sendFirmware(File firmwareFile) async {
    final bytes = await firmwareFile.readAsBytes();

    const int chunkSize = 512; // Ajusta según el MTU configurado
    final totalChunks = (bytes.length / chunkSize).ceil();

    print("Tamaño total: ${bytes.length} bytes, enviando en $totalChunks fragmentos.");

    await sendCommand("OTA_BEGIN");
    await Future.delayed(const Duration(milliseconds: 300));

    for (int i = 0; i < bytes.length; i += chunkSize) {
      final end = (i + chunkSize > bytes.length) ? bytes.length : i + chunkSize;
      final chunk = bytes.sublist(i, end);

      await _ble.writeCharacteristicWithoutResponse(otaCharacteristic, value: chunk);

      if (i % (chunkSize * 10) == 0) {
        print("Enviado ${((i / bytes.length) * 100).toStringAsFixed(1)}%");
      }

      await Future.delayed(const Duration(milliseconds: 20)); // regula velocidad
    }

    await Future.delayed(const Duration(milliseconds: 300));
    await sendCommand("OTA_END");
    print("OTA completada.");
  }
}
