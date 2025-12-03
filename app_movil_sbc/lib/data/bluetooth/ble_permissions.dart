import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';


class BlePermissions {
  /// Pide los permisos necesarios dependiendo de la versión de Android.
  static Future<bool> ensureBlePermissions() async {
    if (!Platform.isAndroid) return true;

    final sdk = await _androidSdk();

    // ---------------------------------------------------
    // ANDROID 12+ (API 31+): BLE necesita permisos BLE nativos
    // ---------------------------------------------------
    if (sdk >= 31) {
      final scan = await Permission.bluetoothScan.request();
      final connect = await Permission.bluetoothConnect.request();

      return scan.isGranted && connect.isGranted;
    }

    // ---------------------------------------------------
    // ANDROID 6–11: BLE necesita permiso de localización
    // ---------------------------------------------------
    final loc = await Permission.locationWhenInUse.request();

    return loc.isGranted;
  }

  /// Devuelve el número de API de Android.
  static Future<int> _androidSdk() async {
    final deviceInfo = DeviceInfoPlugin();
    final info = await deviceInfo.androidInfo;
    return info.version.sdkInt;
  }
}
