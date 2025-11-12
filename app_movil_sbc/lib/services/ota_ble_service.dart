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
      if (ble.connectedDevice == null) {
        onStatus("❌ Dispositivo no conectado");
        return;
      }

      // Solicitar MTU seguro
      int mtu = 23;
      try {
        mtu = await ble.requestMtu(200); // MTU recomendado para Android
        onStatus("📶 MTU negociado: $mtu");
      } catch (_) {
        onStatus("⚠️ No se pudo solicitar MTU grande, se usará valor por defecto");
      }

      final chunkSize = mtu - 3; // ATT header

      // Iniciar OTA
      onStatus("🚀 Enviando comando OTA_BEGIN...");
      await ble.send("OTA_BEGIN");
      await Future.delayed(const Duration(milliseconds: 300));

      final total = firmware.length;
      int sent = 0;

      onStatus("📦 Enviando firmware...");

      while (sent < total) {
        if (ble.connectedDevice == null) {
          onStatus("❌ Dispositivo desconectado durante OTA");
          return;
        }

        final end = (sent + chunkSize > total) ? total : sent + chunkSize;
        final chunk = firmware.sublist(sent, end);

        await ble.write(chunk);
        sent = end;

        onProgress(sent / total);
        await Future.delayed(const Duration(milliseconds: 50)); // espera entre chunks
      }

      onStatus("✅ Enviando comando OTA_END...");
      await ble.send("OTA_END");

      onStatus("🔥 OTA completada. Reiniciando ESP32...");
    } catch (e) {
      onStatus("❌ Error durante OTA: $e");
      rethrow;
    }
  }
}
