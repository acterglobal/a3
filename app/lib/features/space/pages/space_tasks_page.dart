import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/tasks/providers/tasklists.dart';
import 'package:acter/features/tasks/sheets/create_update_task_list.dart';
import 'package:acter/features/tasks/widgets/empty_task_list.dart';
import 'package:acter/features/tasks/widgets/task_list_item_card.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SpaceTasksPage extends ConsumerWidget {
  static const createTaskKey = Key('space-create-task');
  static const scrollView = Key('space-task-lists');
  final String spaceIdOrAlias;

  SpaceTasksPage({super.key, required this.spaceIdOrAlias});

  final ValueNotifier<bool> showCompletedTask = ValueNotifier(false);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskLists = ref.watch(spaceTasksListsProvider(spaceIdOrAlias));
    final spaceName =
        ref.watch(roomDisplayNameProvider(spaceIdOrAlias)).valueOrNull;
    // get platform of context.
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(L10n.of(context).tasks),
            Text(
              '($spaceName)',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        actions: [
          ValueListenableBuilder(
            valueListenable: showCompletedTask,
            builder: (context, value, child) {
              return TextButton.icon(
                onPressed: () => showCompletedTask.value = !value,
                icon: Icon(
                  value
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                ),
                label: Text(
                  value
                      ? L10n.of(context).hideCompleted
                      : L10n.of(context).showCompleted,
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              );
            },
          ),
          IconButton(
            key: createTaskKey,
            icon: const Icon(Atlas.plus_circle_thin),
            iconSize: 28,
            color: Theme.of(context).colorScheme.surface,
            onPressed: () => showCreateUpdateTaskListBottomSheet(
              context,
              initialSelectedSpace: spaceIdOrAlias,
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        key: scrollView,
        slivers: [
          taskLists.when(
            data: (taskLists) {
              if (taskLists.isEmpty) {
                return SliverToBoxAdapter(
                  child: EmptyTaskList(initialSelectedSpace: spaceIdOrAlias),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    TaskList taskList = taskLists[index];
                    return ValueListenableBuilder(
                      valueListenable: showCompletedTask,
                      builder: (context, value, child) {
                        return TaskListItemCard(
                          taskList: taskList,
                          showCompletedTask: value,
                        );
                      },
                    );
                  },
                  childCount: taskLists.length,
                ),
              );
            },
            error: (error, stack) => SliverToBoxAdapter(
              child: SizedBox(
                height: 450,
                child: Center(
                  child: Text(L10n.of(context).loadingFailed(error)),
                ),
              ),
            ),
            loading: () => SliverToBoxAdapter(
              child: SizedBox(
                height: 450,
                child: Center(
                  child: Text(L10n.of(context).loading),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
