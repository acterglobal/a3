import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/acter_icon_picker/acter_icon_widget.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/color_data.dart';
import 'package:acter/common/widgets/reference_details_item.dart';
import 'package:acter/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:acter/features/bookmarks/types.dart';
import 'package:acter/features/deep_linking/widgets/reference_details_item.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter/features/tasks/widgets/task_items_list_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

class TaskListItemCard extends ConsumerWidget {
  final String taskListId;
  final RefDetails? refDetails;
  final bool showSpace;
  final bool showTaskListIndication;
  final bool showCompletedTask;
  final bool showOnlyTaskList;
  final bool initiallyExpanded;
  final bool canExpand;
  final EdgeInsetsGeometry? cardMargin;
  final GestureTapCallback? onTitleTap;

  const TaskListItemCard({
    super.key,
    required this.taskListId,
    this.refDetails,
    this.showSpace = false,
    this.showTaskListIndication = false,
    this.showCompletedTask = false,
    this.showOnlyTaskList = false,
    this.initiallyExpanded = true,
    this.canExpand = true,
    this.cardMargin,
    this.onTitleTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskList = ref.watch(taskListProvider(taskListId)).valueOrNull;
    final isBookmarked = ref.watch(isBookmarkedProvider(BookmarkType.forTaskList(taskListId)));
    if (taskList != null) {
      return Card(
        margin: cardMargin,
        key: Key('task-list-card-$taskListId'),
        child: Stack(
          children: [
            taskListItemView(context, ref, taskList),
            if (isBookmarked) buildTaskBookmarkView(context),
          ],
        ),
      );
    } else if (refDetails != null) {
      return ReferenceDetailsItem(refDetails: refDetails!);
    } else {
      return const Skeletonizer(child: SizedBox(height: 100, width: 100));
    }
  }

  Widget taskListItemView(
    BuildContext context,
    WidgetRef ref,
    TaskList taskList,
  ) {
    return canExpand
        ? expandable(context, ref, taskList)
        : simple(context, ref, taskList);
  }

  Widget expandable(BuildContext context, WidgetRef ref, TaskList taskList) {
    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      leading: ActerIconWidget(
        iconSize: 30,
        color: convertColor(
          taskList.display()?.color(),
          iconPickerColors[0],
        ),
        icon: ActerIcon.iconForTask(taskList.display()?.iconStr()),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      iconColor: Theme.of(context).colorScheme.onSurface,
      childrenPadding: const EdgeInsets.symmetric(horizontal: 10),
      title: title(context, taskList),
      subtitle: subtitle(ref, taskList),
      children: showOnlyTaskList
          ? []
          : [
              TaskItemsListWidget(
                taskList: taskList,
                showCompletedTask: showCompletedTask,
              ),
            ],
    );
  }

  Widget buildTaskBookmarkView(BuildContext context) {
    return Positioned(
      right: 15,
      top: -4,
      child: Icon(
        Icons.bookmark_sharp,
        color: Theme.of(context).unselectedWidgetColor,
        size: 24,
      ),
    );
  }

  Widget simple(BuildContext context, WidgetRef ref, TaskList taskList) =>
      ListTile(
        leading: ActerIconWidget(
          iconSize: 30,
          color: convertColor(
            taskList.display()?.color(),
            iconPickerColors[0],
          ),
          icon: ActerIcon.iconForTask(taskList.display()?.iconStr()),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        iconColor: Theme.of(context).colorScheme.onSurface,
        title: title(context, taskList),
        subtitle: subtitle(ref, taskList),
      );

  Widget title(BuildContext context, TaskList taskList) {
    return InkWell(
      onTap: onTitleTap ??
          () {
            context.pushNamed(
              Routes.taskListDetails.name,
              pathParameters: {'taskListId': taskListId},
            );
          },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            key: Key('task-list-title-$taskListId'),
            taskList.name(),
          ),
          if (showTaskListIndication)
            Row(
              children: [
                Icon(Atlas.list, size: 16),
                SizedBox(width: 6),
                Text(
                  L10n.of(context).taskList,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget? subtitle(WidgetRef ref, TaskList taskList) {
    if (!showSpace) return null;
    return SpaceChip(spaceId: taskList.spaceIdStr(), useCompactView: true);
  }
}
