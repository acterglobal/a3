import 'dart:core';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/tasks/providers/tasklists.dart';
import 'package:acter/features/tasks/widgets/all_tasks_done.dart';
import 'package:acter/features/tasks/widgets/task_list_card.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:go_router/go_router.dart';

class SpaceTasksPage extends ConsumerWidget {
  final String spaceIdOrAlias;
  const SpaceTasksPage({super.key, required this.spaceIdOrAlias});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskLists = ref.watch(spaceTasksListsProvider(spaceIdOrAlias));
    // get platform of context.
    return Padding(
      padding: const EdgeInsets.all(20),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Tasks',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Atlas.plus_circle_thin,
                    color: Theme.of(context).colorScheme.neutral5,
                  ),
                  iconSize: 28,
                  color: Theme.of(context).colorScheme.surface,
                  onPressed: () => context.pushNamed(
                    Routes.actionAddPin.name,
                    queryParameters: {'spaceId': spaceIdOrAlias},
                  ),
                ),
              ],
            ),
          ),
          taskLists.when(
            data: (taskLists) {
              if (taskLists.isEmpty) {
                return const SliverToBoxAdapter(child: AllTasksDone());
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    TaskList taskList = taskLists[index];
                    return TaskListCard(taskList: taskList);
                  },
                  childCount: taskLists.length,
                ),
              );
            },
            error: (error, stack) => SliverToBoxAdapter(
              child: SizedBox(
                height: 450,
                child: Center(
                  child: Text('Loading tasks failed: $error'),
                ),
              ),
            ),
            loading: () => const SliverToBoxAdapter(
              child: SizedBox(
                height: 450,
                child: Center(
                  child: Text('Loading'),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
