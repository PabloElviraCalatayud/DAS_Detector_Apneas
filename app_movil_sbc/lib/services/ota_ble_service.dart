import 'dart:typed_data';
import 'dart:async';

import '../data/bluetooth/ble_manager.dart';


class OtaBleService {
  final BleManager ble;

  OtaBleService(this.ble);

  Future<void> startOta(
      Uint8List firmware, {
        required Function(double) onProgress,
        required Function(String) onStatus,
      }) async {
    try {
      if (!ble.isConnected) {
        onStatus("❌ Dispositivo no conectado");
        return;
      }

      int mtu = 23;
      try {
        mtu = await ble.requestMtu(200);
        onStatus("📶 MTU negociado: $mtu");
      } catch (_) {
        onStatus("⚠️ No se pudo solicitar MTU grande, usando el mínimo");
      }

      final chunkSize = mtu - 3;

      onStatus("🚀 Enviando comando OTA_BEGIN...");
      await ble.sendText("OTA_BEGIN");
      await Future.delayed(const Duration(milliseconds: 300));

      final total = firmware.length;
      int sent = 0;

      onStatus("📦 Enviando firmware...");

      while (sent < total) {
        if (!ble.isConnected) {
          onStatus("❌ Desconectado durante la OTA");
          return;
        }

        final end = (sent + chunkSize > total) ? total : sent + chunkSize;
        final chunk = firmware.sublist(sent, end);

        await ble.writeBinary(Uint8List.fromList(chunk));
        sent = end;

        onProgress(sent / total);

        await Future.delayed(const Duration(milliseconds: 40));
      }

      onStatus("✅ Enviando comando OTA_END...");
      await ble.sendText("OTA_END");

      onStatus("🔥 OTA completada. Reiniciando ESP32...");

    } catch (e) {
      onStatus("❌ Error durante OTA: $e");
      rethrow;
    }
  }
}
