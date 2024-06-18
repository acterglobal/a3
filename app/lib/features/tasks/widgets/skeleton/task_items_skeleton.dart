import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class TaskItemsSkeleton extends StatelessWidget {
  const TaskItemsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: Column(
        children: [
          taskItem(context),
          taskItem(context),
          taskItem(context),
        ],
      ),
    );
  }

  Widget taskItem(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.radio_button_off_outlined),
      title: Text(L10n.of(context).taskName),
      subtitle: Text(L10n.of(context).taskName),
    );
  }
}
