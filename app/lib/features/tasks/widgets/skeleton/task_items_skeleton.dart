import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:skeletonizer/skeletonizer.dart';

class TaskItemsSkeleton extends StatelessWidget {
  const TaskItemsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: Column(
        children: [taskItem(context), taskItem(context), taskItem(context)],
      ),
    );
  }

  Widget taskItem(BuildContext context) {
    final lang = L10n.of(context);
    return ListTile(
      leading: const Icon(Icons.radio_button_off_outlined),
      title: Text(lang.taskName),
      subtitle: Text(lang.taskName),
    );
  }
}
