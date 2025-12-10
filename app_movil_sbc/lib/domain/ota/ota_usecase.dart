import 'dart:typed_data';
import '../../data/bluetooth/ota/ota_service.dart';

class OtaUsecase {
  final OtaService otaService;

  OtaUsecase(this.otaService);

  Future<void> execute(
      Uint8List firmware, {
        required Function(double) onProgress,
        required Function(String) onStatus,
      }) async {

    await otaService.sendBegin();

    final mtu = await otaService.ble.requestMtu(200);
    final chunkSize = mtu - 3;

    int sent = 0;
    final total = firmware.length;

    onStatus("Enviando firmware...");

    while (sent < total) {
      final end = (sent + chunkSize > total) ? total : sent + chunkSize;
      final chunk = firmware.sublist(sent, end);

      await otaService.sendChunk(Uint8List.fromList(chunk));

      sent = end;
      onProgress(sent / total);
    }

    await otaService.sendEnd();
  }
}
