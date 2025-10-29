import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'ui/pages/ble_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE Bidireccional ESP32',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const BlePage(),
    );
  }
}
