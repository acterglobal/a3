import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/space/widgets/space_header.dart';
import 'package:acter/features/tasks/providers/tasklists.dart';
import 'package:acter/features/tasks/widgets/all_tasks_done.dart';
import 'package:acter/features/tasks/widgets/task_list_card.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SpaceTasksPage extends ConsumerWidget {
  static const createTaskKey = Key('space-create-task');
  static const scrollView = Key('space-task-lists');
  final String spaceIdOrAlias;

  const SpaceTasksPage({super.key, required this.spaceIdOrAlias});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskLists = ref.watch(spaceTasksListsProvider(spaceIdOrAlias));
    // get platform of context.
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: primaryGradient),
      child: CustomScrollView(
        key: scrollView,
        slivers: [
          SliverToBoxAdapter(
            child: SpaceHeader(spaceIdOrAlias: spaceIdOrAlias),
          ),
          SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    taskLists.hasValue && taskLists.valueOrNull!.isNotEmpty
                        ? L10n.of(context)
                            .tasksCount(taskLists.valueOrNull!.length)
                        : L10n.of(context).tasks,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: createTaskKey,
                  icon: Icon(
                    Atlas.plus_circle_thin,
                    color: Theme.of(context).colorScheme.neutral5,
                  ),
                  iconSize: 28,
                  color: Theme.of(context).colorScheme.surface,
                  onPressed: () => context.pushNamed(
                    Routes.actionAddTaskList.name,
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
