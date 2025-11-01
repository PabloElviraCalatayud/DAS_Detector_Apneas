import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'common/core/themes.dart';
import 'app_router.dart';
import 'data/bluetooth/ble_manager.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BleManager()), // ✅ instancia global
      ],
      child: const InsoleApp(),
    ),
  );
}

class InsoleApp extends StatelessWidget {
  const InsoleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DAS',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/onboarding',
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
