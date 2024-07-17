import 'dart:math';

import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/add_button_with_can_permission.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter/features/tasks/sheets/create_update_task_list.dart';
import 'package:acter/features/tasks/widgets/skeleton/tasks_list_skeleton.dart';
import 'package:acter/features/tasks/widgets/task_list_item_card.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:acter/features/search/providers/search.dart';

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
  final TextEditingController searchTextController = TextEditingController();

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
    return AppBar(
      centerTitle: false,
      title: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L10n.of(context).tasks),
          if (widget.spaceId != null) _buildSpaceName(),
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
        AddButtonWithCanPermission(
          key: TasksListPage.createNewTaskListKey,
          canString: 'CanPostTaskList',
          onPressed: () => showCreateUpdateTaskListBottomSheet(
            context,
            initialSelectedSpace: widget.spaceId,
          ),
        ),
      ],
    );
  }

  Widget _buildSpaceName() {
    String spaceName =
        ref.watch(roomDisplayNameProvider(widget.spaceId!)).valueOrNull ?? '';
    return Text(
      '($spaceName)',
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelLarge,
    );
  }

  Widget _buildBody() {
    AsyncValue<List<TaskList>> tasksList;

    tasksList = ref.watch(
      tasksListSearchProvider(
        (spaceId: widget.spaceId, searchText: searchValue),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSearchBar(),
        Expanded(
          child: tasksList.when(
            data: (tasks) => _buildTasksList(tasks),
            error: (error, stack) =>
                Center(child: Text(L10n.of(context).loadingFailed(error))),
            loading: () => const TasksListSkeleton(),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: SearchBar(
        controller: searchTextController,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(Atlas.magnifying_glass),
        ),
        hintText: L10n.of(context).search,
        trailing: searchValue.isNotEmpty
            ? [
                IconButton(
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    ref.read(searchValueProvider.notifier).state = '';
                    searchTextController.clear();
                  },
                  icon: const Icon(Icons.clear),
                ),
              ]
            : null,
        onChanged: (value) =>
            ref.read(searchValueProvider.notifier).state = value,
      ),
    );
  }

  Widget _buildTasksList(List<TaskList> tasksList) {
    final size = MediaQuery.of(context).size;
    final widthCount = (size.width ~/ 500).toInt();
    const int minCount = 2;

    if (tasksList.isEmpty) return _buildTasksListEmptyState();

    return SingleChildScrollView(
      key: TasksListPage.scrollView,
      child: StaggeredGrid.count(
        crossAxisCount: max(1, min(widthCount, minCount)),
        children: [
          for (var taskList in tasksList)
            ValueListenableBuilder(
              valueListenable: showCompletedTask,
              builder: (context, value, child) {
                return TaskListItemCard(
                  taskList: taskList,
                  showCompletedTask: value,
                  showSpace: widget.spaceId == null,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTasksListEmptyState() {
    bool canAdd = false;
    if (searchValue.isEmpty) {
      canAdd = ref
              .watch(hasSpaceWithPermissionProvider('CanPostTaskList'))
              .valueOrNull ??
          false;
    }
    return Center(
      heightFactor: 1,
      child: EmptyState(
        title: searchValue.isNotEmpty
            ? L10n.of(context).noMatchingTasksListFound
            : L10n.of(context).noTasksListAvailableYet,
        subtitle: L10n.of(context).noTasksListAvailableDescription,
        image: 'assets/images/tasks.svg',
        primaryButton: canAdd && searchValue.isEmpty
            ? ActerPrimaryActionButton(
                onPressed: () => showCreateUpdateTaskListBottomSheet(
                  context,
                  initialSelectedSpace: widget.spaceId,
                ),
                child: Text(L10n.of(context).createTaskList),
              )
            : null,
      ),
    );
  }
}
