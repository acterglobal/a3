import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:acter/common/widgets/add_button_with_can_permission.dart';
import 'package:acter/common/widgets/space_name_widget.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter/features/tasks/sheets/create_update_task_list.dart';
import 'package:acter/features/tasks/widgets/task_list_widget.dart';
import 'package:acter/features/tasks/widgets/task_lists_empty.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TasksListPage extends ConsumerStatefulWidget {
  static const scrollView = Key('space-task-lists');
  static const createNewTaskListKey = Key('tasks-create-list');
  static const taskListsKey = Key('tasks-task-lists');

  final String? spaceId;
  final String? searchQuery;
  final bool showOnlyTaskList;
  final Function(String)? onSelectTaskListItem;

  const TasksListPage({
    super.key,
    this.spaceId,
    this.searchQuery,
    this.showOnlyTaskList = false,
    this.onSelectTaskListItem,
  });

  @override
  ConsumerState<TasksListPage> createState() => _TasksListPageConsumerState();
}

class _TasksListPageConsumerState extends ConsumerState<TasksListPage> {
  String get searchValue => ref.watch(taskListSearchTermProvider);
  final ValueNotifier<bool> showCompletedTask = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      ref.read(taskListSearchTermProvider.notifier).state =
          widget.searchQuery ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppBar(), body: _buildBody());
  }

  AppBar _buildAppBar() {
    final lang = L10n.of(context);
    final spaceId = widget.spaceId;
    return AppBar(
      centerTitle: false,
      title:
          widget.onSelectTaskListItem != null
              ? Text(L10n.of(context).selectTaskList)
              : Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lang.tasks),
                  if (spaceId != null) SpaceNameWidget(spaceId: spaceId),
                ],
              ),
      actions: [
        if (!widget.showOnlyTaskList)
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
                label: Text(value ? lang.hideCompleted : lang.showCompleted),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              );
            },
          ),
        AddButtonWithCanPermission(
          key: TasksListPage.createNewTaskListKey,
          spaceId: spaceId,
          canString: 'CanPostTaskList',
          onPressed:
              () => showCreateUpdateTaskListBottomSheet(
                context,
                initialSelectedSpace: spaceId,
              ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActerSearchWidget(
          initialText: widget.searchQuery,
          onChanged: (value) {
            final notifier = ref.read(taskListSearchTermProvider.notifier);
            notifier.state = value;
          },
          onClear: () {
            final notifier = ref.read(taskListSearchTermProvider.notifier);
            notifier.state = '';
          },
        ),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: showCompletedTask,
            builder:
                (context, value, child) => TaskListWidget(
                  taskListProvider: tasksListSearchProvider(widget.spaceId),
                  spaceId: widget.spaceId,
                  shrinkWrap: false,
                  showOnlyTaskList: widget.showOnlyTaskList,
                  showCompletedTask: showCompletedTask.value,
                  onSelectTaskListItem: widget.onSelectTaskListItem,
                  emptyState: _taskListsEmptyState(),
                ),
          ),
        ),
      ],
    );
  }

  Widget _taskListsEmptyState() {
    var canAdd = false;
    if (searchValue.isEmpty) {
      final canPostLoader = ref.watch(
        hasSpaceWithPermissionProvider('CanPostTaskList'),
      );
      if (canPostLoader.valueOrNull == true) canAdd = true;
    }
    return TaskListsEmptyState(
      canAdd: canAdd,
      inSearch: searchValue.isNotEmpty,
      spaceId: widget.spaceId,
    );
  }
}
