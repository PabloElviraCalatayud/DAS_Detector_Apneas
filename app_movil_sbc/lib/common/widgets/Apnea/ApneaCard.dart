import 'package:flutter/material.dart';
import 'package:flutter/material.dart';

class ApneaCard extends StatelessWidget {
  final int apneaEvents;

  const ApneaCard({super.key, required this.apneaEvents});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.health_and_safety,
                  size: 26,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text(
                "Apneas del Sueño",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "$apneaEvents",
            style: const TextStyle(
              fontSize: 46,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
