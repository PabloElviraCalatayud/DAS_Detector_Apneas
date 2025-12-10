import 'dart:typed_data';
import '../manager/ble_manager.dart';
import 'ota_protocol.dart';

class OtaService {
  final BleManager ble;

  OtaService(this.ble);

  Future<void> sendBegin() {
    return ble.sendText(OtaProtocol.cmdBegin);
  }

  Future<void> sendEnd() {
    return ble.sendText(OtaProtocol.cmdEnd);
  }

  Future<void> sendChunk(Uint8List chunk) {
    return ble.writeBinary(chunk);
  }
}
