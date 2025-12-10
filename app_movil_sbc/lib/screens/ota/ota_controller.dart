import 'dart:typed_data';
import '../../domain/ota/ota_usecase.dart';

class OtaController {
  final OtaUsecase usecase;

  OtaController(this.usecase);

  Future<void> start(
      Uint8List bin,
      Function(double) onProgress,
      Function(String) onStatus,
      ) async {

    onStatus("Iniciando OTA...");

    try {
      await usecase.execute(
        bin,
        onProgress: onProgress,
        onStatus: onStatus,
      );

      onStatus("OTA completa.");
    } catch (e) {
      onStatus("Error OTA: $e");
    }
  }
}
