import 'package:app_movil_sbc/screens/OTA/OTA_page.dart';
import 'package:flutter/material.dart';
import 'data/bluetooth/ble_manager.dart';
import 'screens/onboarding/onboarding_page.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/bluetooth/ble_page.dart';
import 'screens/debug/debug_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/onboarding': {
        return MaterialPageRoute(builder: (_) {
          return const OnboardingPage();
        });
      }

      case '/dashboard': {
        return MaterialPageRoute(builder: (_) {
          return const DashboardScreen();
        });
      }

      case '/bluetooth': {
        return MaterialPageRoute(builder: (_) {
          return const BLEPage();
        });
      }

      case '/ota': {
        return MaterialPageRoute(builder: (_) {
          return const OtaPage();
        });
      }

      case '/debug': {
        return MaterialPageRoute(builder: (_) {
          return DebugScreen(packetStream: BleManager.instance.packetStream,);
        });
      }

      default: {
        return MaterialPageRoute(builder: (_) {
          return const DashboardScreen();
        });
      }
    }
  }
}
