import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class QuickActionButtons extends StatelessWidget {
  const QuickActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(PhosphorIcons.pingPong()),
              const SizedBox(width: 14),
              const Text('Option-1')
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(PhosphorIcons.calendar()),
              const SizedBox(width: 14),
              const Text("Option-1")
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(PhosphorIcons.list()),
              const SizedBox(width: 14),
              const Text("Option-1")
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(PhosphorIcons.broadcast()),
              const SizedBox(width: 14),
              const Text("Add Boast")
            ],
          ),
        ),
      ],
    );
  }
}
