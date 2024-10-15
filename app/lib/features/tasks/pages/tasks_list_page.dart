import 'dart:math';

import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/toolkit/errors/error_page.dart';
import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:acter/common/widgets/add_button_with_can_permission.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/common/widgets/space_name_widget.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter/features/tasks/sheets/create_update_task_list.dart';
import 'package:acter/features/tasks/widgets/skeleton/tasks_list_skeleton.dart';
import 'package:acter/features/tasks/widgets/task_list_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::tasks::tasklist');

class TasksListPage extends ConsumerStatefulWidget {
  static const scrollView = Key('space-task-lists');
  static const createNewTaskListKey = Key('tasks-create-list');
  static const taskListsKey = Key('tasks-task-lists');
  final String? spaceId;

  const TasksListPage({super.key, this.spaceId});

  @override
  ConsumerState<TasksListPage> createState() => _TasksListPageConsumerState();
}

class _TasksListPageConsumerState extends ConsumerState<TasksListPage> {
  String get searchValue => ref.watch(searchValueProvider);
  final ValueNotifier<bool> showCompletedTask = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    final lang = L10n.of(context);
    return AppBar(
      centerTitle: false,
      title: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lang.tasks),
          if (widget.spaceId != null)
            SpaceNameWidget(
              spaceId: widget.spaceId!,
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
                value ? lang.hideCompleted : lang.showCompleted,
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            );
          },
        ),
        AddButtonWithCanPermission(
          key: TasksListPage.createNewTaskListKey,
          spaceId: widget.spaceId,
          canString: 'CanPostTaskList',
          onPressed: () => showCreateUpdateTaskListBottomSheet(
            context,
            initialSelectedSpace: widget.spaceId,
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    final tasklistsLoader = ref.watch(
      tasksListSearchProvider(
        (spaceId: widget.spaceId, searchText: searchValue),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActerSearchWidget(
          onChanged: (value) =>
              ref.read(searchValueProvider.notifier).state = value,
          onClear: () => ref.read(searchValueProvider.notifier).state = '',
        ),
        Expanded(
          child: tasklistsLoader.when(
            data: (tasklists) => _buildTasklists(tasklists),
            error: (error, stack) {
              _log.severe('Failed to search tasklists in space', error, stack);
              return ErrorPage(
                background: const TasksListSkeleton(),
                error: error,
                stack: stack,
                onRetryTap: () {
                  ref.invalidate(allTasksListsProvider);
                },
              );
            },
            loading: () => const TasksListSkeleton(),
          ),
        ),
      ],
    );
  }

  Widget _buildTasklists(List<String> tasklists) {
    final size = MediaQuery.of(context).size;
    final widthCount = (size.width ~/ 500).toInt();
    const int minCount = 2;

    if (tasklists.isEmpty) return _buildTasklistsEmptyState();

    return SingleChildScrollView(
      key: TasksListPage.scrollView,
      child: StaggeredGrid.count(
        crossAxisCount: max(1, min(widthCount, minCount)),
        children: [
          for (final tasklistId in tasklists)
            ValueListenableBuilder(
              valueListenable: showCompletedTask,
              builder: (context, value, child) => TaskListItemCard(
                taskListId: tasklistId,
                showCompletedTask: value,
                showSpace: widget.spaceId == null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTasklistsEmptyState() {
    final lang = L10n.of(context);
    var canAdd = false;
    if (searchValue.isEmpty) {
      final canPostLoader = ref.watch(
        hasSpaceWithPermissionProvider('CanPostTaskList'),
      );
      if (canPostLoader.valueOrNull == true) canAdd = true;
    }
    return Center(
      heightFactor: 1,
      child: EmptyState(
        title: searchValue.isNotEmpty
            ? lang.noMatchingTasksListFound
            : lang.noTasksListAvailableYet,
        subtitle: lang.noTasksListAvailableDescription,
        image: 'assets/images/tasks.svg',
        primaryButton: canAdd
            ? ActerPrimaryActionButton(
                onPressed: () => showCreateUpdateTaskListBottomSheet(
                  context,
                  initialSelectedSpace: widget.spaceId,
                ),
                child: Text(lang.createTaskList),
              )
            : null,
      ),
    );
  }
}
