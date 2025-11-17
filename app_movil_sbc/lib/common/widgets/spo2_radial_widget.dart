import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/bluetooth/ble_manager.dart';

class SpO2Widget extends StatelessWidget {
  const SpO2Widget({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = context.watch<BleManager>();

    // Por ahora → valor fijo hasta que tengamos SpO2 real
    final int spo2 = 97;

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: spo2 / 100,
                  strokeWidth: 6,
                  backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.2),
                  color: Theme.of(context).colorScheme.secondary,
                ),
                Text('$spo2',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "$spo2%",
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 36,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
