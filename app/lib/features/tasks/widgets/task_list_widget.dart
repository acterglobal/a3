import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/toolkit/errors/error_page.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter/features/tasks/widgets/skeleton/tasks_list_skeleton.dart';
import 'package:acter/features/tasks/widgets/task_list_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::task-list::widget');

class TaskListWidget extends ConsumerWidget {
  final ProviderBase<AsyncValue<List<String>>> taskListProvider;
  final String? spaceId;
  final int? limit;
  final bool showOnlyTaskList;
  final bool initiallyExpanded;
  final bool showCompletedTask;
  final bool showSectionHeader;
  final VoidCallback? onClickSectionHeader;
  final Function(String)? onSelectTaskListItem;
  final bool shrinkWrap;
  final Widget emptyState;

  const TaskListWidget({
    super.key,
    required this.taskListProvider,
    this.limit,
    this.spaceId,
    this.showOnlyTaskList = false,
    this.initiallyExpanded = true,
    this.showCompletedTask = false,
    this.showSectionHeader = false,
    this.onClickSectionHeader,
    this.onSelectTaskListItem,
    this.shrinkWrap = true,
    this.emptyState = const SizedBox.shrink(),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskListLoader = ref.watch(taskListProvider);

    return taskListLoader.when(
      data: (taskList) => buildTaskSectionUI(context, taskList),
      error: (error, stack) => taskListErrorWidget(context, ref, error, stack),
      loading: () => const TasksListSkeleton(),
    );
  }

  Widget taskListErrorWidget(
    BuildContext context,
    WidgetRef ref,
    Object error,
    StackTrace stack,
  ) {
    _log.severe('Failed to load task list', error, stack);
    return ErrorPage(
      background: const TasksListSkeleton(),
      error: error,
      stack: stack,
      textBuilder: (error, code) => L10n.of(context).loadingFailed(error),
      onRetryTap: () {
        ref.invalidate(taskListProvider);
      },
    );
  }

  Widget buildTaskSectionUI(BuildContext context, List<String> taskList) {
    if (taskList.isEmpty) return emptyState;

    final count = (limit ?? taskList.length).clamp(0, taskList.length);
    return showSectionHeader
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SectionHeader(
                title: L10n.of(context).tasks,
                isShowSeeAllButton: count < taskList.length,
                onTapSeeAll: onClickSectionHeader.map((cb) => () => cb()),
              ),
              taskListUI(taskList, count),
            ],
          )
        : taskListUI(taskList, count);
  }

  Widget taskListUI(List<String> taskList, int count) {
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      itemCount: count,
      padding: EdgeInsets.zero,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemBuilder: (context, index) {
        return TaskListItemCard(
          taskListId: taskList[index],
          showCompletedTask: showCompletedTask,
          showOnlyTaskList: showOnlyTaskList,
          canExpand: !showOnlyTaskList,
          initiallyExpanded: initiallyExpanded,
          onTitleTap: () {
            if (onSelectTaskListItem != null) {
              onSelectTaskListItem!(taskList[index]);
            } else {
              context.pushNamed(
                Routes.taskListDetails.name,
                pathParameters: {'taskListId': taskList[index]},
              );
            }
          },
          showSpace: spaceId == null,
        );
      },
    );
  }
}
