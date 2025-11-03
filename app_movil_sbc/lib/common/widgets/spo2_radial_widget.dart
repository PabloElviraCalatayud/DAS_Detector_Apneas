import 'package:flutter/material.dart';

class SpO2Widget extends StatelessWidget {
  final int value;
  const SpO2Widget({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
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
                  value: value / 100,
                  strokeWidth: 6,
                  backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.2),
                  color: Theme.of(context).colorScheme.secondary,
                ),
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "$value%",
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
