import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BleConstants {
  static final serviceUuid = Uuid.parse("12345678-90ab-cdef-1234-567890abcdef");
  static final writeCharacteristicUuid = Uuid.parse("12345678-90ab-cdef-1234-567890abcdefe1");
  static final notifyCharacteristicUuid = Uuid.parse("12345678-90ab-cdef-1234-567890abcdefe2");
}
