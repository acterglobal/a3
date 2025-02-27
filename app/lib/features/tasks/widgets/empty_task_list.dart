import 'package:acter/features/tasks/sheets/create_update_task_list.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/l10n.dart';

class EmptyTaskList extends StatelessWidget {
  final String? initialSelectedSpace;

  const EmptyTaskList({super.key, this.initialSelectedSpace});

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return SizedBox(
      height: 450,
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Atlas.list, size: 50),
            const SizedBox(height: 20),
            Text(
              lang.emptyTaskList,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed:
                  () => showCreateUpdateTaskListBottomSheet(
                    context,
                    initialSelectedSpace: initialSelectedSpace,
                  ),
              child: Text(lang.createTaskList),
            ),
          ],
        ),
      ),
    );
  }
}
