import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ObjectIconWidget extends StatelessWidget {
  final String? objectType;
  const ObjectIconWidget({super.key, required this.objectType});

  @override
  Widget build(BuildContext context) {
    return Icon(
      _getActivityObjectIcon(),
      size: 18,
      color: Theme.of(context).colorScheme.surfaceTint,
    );
  }

  IconData _getActivityObjectIcon() {
    return switch (objectType) {
      'news' => PhosphorIconsRegular.rocketLaunch,
      'story' => PhosphorIconsRegular.book,
      'event' => PhosphorIconsRegular.calendar,
      'pin' => PhosphorIconsRegular.pushPin,
      'task-list' => PhosphorIconsRegular.listChecks,
      'task' => PhosphorIconsRegular.checkCircle,
      _ => PhosphorIconsRegular.question,
    };
  }
}
