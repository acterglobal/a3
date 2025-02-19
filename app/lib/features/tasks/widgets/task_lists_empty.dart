import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/tasks/sheets/create_update_task_list.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskListsEmptyState extends ConsumerWidget {
  final bool canAdd;
  final bool inSearch;
  final String? spaceId;
  const TaskListsEmptyState({
    super.key,
    required this.canAdd,
    required this.inSearch,
    this.spaceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return Center(
      heightFactor: 1,
      child: EmptyState(
        title: inSearch
            ? lang.noMatchingTasksListFound
            : lang.noTasksListAvailableYet,
        subtitle: lang.noTasksListAvailableDescription,
        image: 'assets/images/tasks.svg',
        primaryButton: canAdd
            ? ActerPrimaryActionButton(
                onPressed: () => showCreateUpdateTaskListBottomSheet(
                  context,
                  initialSelectedSpace: spaceId,
                ),
                child: Text(lang.createTaskList),
              )
            : null,
      ),
    );
  }
}
