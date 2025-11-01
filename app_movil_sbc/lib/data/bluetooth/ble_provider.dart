import 'package:flutter/foundation.dart';
import 'ble_manager.dart';

class BleProvider extends ChangeNotifier {
  final BleManager ble = BleManager();
}
