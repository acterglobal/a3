import 'dart:async';

import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/edit_title_sheet.dart';
import 'package:acter/common/widgets/edit_html_description_sheet.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:acter/features/attachments/widgets/attachment_section.dart';
import 'package:acter/features/comments/widgets/comments_section.dart';
import 'package:acter/features/tasks/providers/tasklists.dart';
import 'package:acter/features/tasks/providers/tasks.dart';
import 'package:acter/features/tasks/sheets/create_update_task_item.dart';
import 'package:acter/features/tasks/widgets/due_picker.dart';
import 'package:acter/features/tasks/widgets/skeleton/task_item_detail_page_skeleton.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::tasks::task_item_details_page');

class TaskItemDetailPage extends ConsumerWidget {
  static const taskListTitleKey = Key('task-list-title');
  final String taskListId;
  final String taskId;

  const TaskItemDetailPage({
    required this.taskListId,
    required this.taskId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task =
        ref.watch(taskProvider((taskListId: taskListId, taskId: taskId)));
    return Scaffold(
      appBar: _buildAppBar(context, ref, task),
      body: _buildBody(context, ref, task),
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Task> task,
  ) {
    return task.when(
      data: (data) => AppBar(
        title: GestureDetector(
          onTap: () => showEditTaskItemNameBottomSheet(
            context: context,
            ref: ref,
            task: data,
            titleValue: data.title(),
          ),
          child: Text(
            data.title(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  onTap: () => showEditDescriptionSheet(context, ref, data),
                  child: Text(
                    L10n.of(context).editDescription,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      error: (e, s) => AppBar(title: Text(L10n.of(context).failedToLoad(e))),
      loading: () => AppBar(title: Text(L10n.of(context).loading)),
    );
  }

  Future<void> editTask(
    BuildContext context,
    WidgetRef ref,
    TaskList? taskList,
    Task? task,
  ) async {
    if (taskList != null && task != null) {
      showCreateUpdateTaskItemBottomSheet(
        context,
        taskList: taskList,
        taskName: task.title(),
        task: task,
      );
    }
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Task> task,
  ) {
    return task.when(
      data: (data) => taskData(context, data, ref),
      error: (e, s) => Text(L10n.of(context).failedToLoad(e)),
      loading: () => const TaskItemDetailPageSkeleton(),
    );
  }

  Widget taskData(BuildContext context, Task task, WidgetRef ref) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _widgetDescription(context, task, ref),
            _widgetListName(context, ref),
            _widgetTaskDate(context, task),
            _widgetTaskAssignment(context, task, ref),
            const SizedBox(height: 20),
            AttachmentSectionWidget(manager: task.attachments()),
            const SizedBox(height: 20),
            CommentsSection(manager: task.comments()),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _widgetDescription(BuildContext context, Task task, WidgetRef ref) {
    final description = task.description();
    if (description == null) return const SizedBox.shrink();
    final formattedBody = description.formattedBody();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            showEditDescriptionSheet(context, ref, task);
          },
          child: formattedBody != null
              ? RenderHtml(
                  text: formattedBody,
                  defaultTextStyle: Theme.of(context).textTheme.labelLarge,
                )
              : Text(
                  description.body(),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
        ),
        const SizedBox(height: 10),
        const Divider(indent: 10, endIndent: 18),
        const SizedBox(height: 10),
      ],
    );
  }

  void showEditDescriptionSheet(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) {
    showEditHtmlDescriptionBottomSheet(
      context: context,
      descriptionHtmlValue: task.description()?.formattedBody(),
      descriptionMarkdownValue: task.description()?.body(),
      onSave: (htmlBodyDescription, plainDescription) {
        _saveDescription(
          context,
          ref,
          task,
          htmlBodyDescription,
          plainDescription,
        );
      },
    );
  }

  Future<void> _saveDescription(
    BuildContext context,
    WidgetRef ref,
    Task task,
    String htmlBodyDescription,
    String plainDescription,
  ) async {
    EasyLoading.show(status: L10n.of(context).updatingDescription);
    try {
      final updater = task.updateBuilder();
      updater.descriptionHtml(plainDescription, htmlBodyDescription);
      await updater.send();
      EasyLoading.dismiss();
      if (context.mounted) context.pop();
    } catch (e, st) {
      _log.severe('Failed to update event description', e, st);
      EasyLoading.dismiss();
      if (!context.mounted) return;
      EasyLoading.showError(
        L10n.of(context).errorUpdatingDescription(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Widget _widgetListName(
    BuildContext context,
    WidgetRef ref,
  ) {
    final taskList = ref.watch(taskListProvider(taskListId));
    return taskList.when(
      data: (d) => ListTile(
        dense: true,
        leading: const Icon(Atlas.list),
        title: Text(
          L10n.of(context).taskList,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        subtitle: Text(
          key: taskListTitleKey,
          d.name(),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          context.pushNamed(
            Routes.taskListDetails.name,
            pathParameters: {'taskListId': taskListId},
          );
        },
      ),
      error: (e, s) => Text(L10n.of(context).failedToLoad(e)),
      loading: () => Text(L10n.of(context).loading),
    );
  }

  Widget _widgetTaskDate(BuildContext context, Task task) {
    return ListTile(
      dense: true,
      leading: const Icon(Atlas.calendar_date_thin),
      title: Text(
        L10n.of(context).dueDate,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      subtitle: Text(
        task.dueDate() != null
            ? taskDueDateFormat(DateTime.parse(task.dueDate()!))
            : L10n.of(context).noDueDate,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () => duePickerAction(context, task),
    );
  }

  Future<void> duePickerAction(BuildContext context, Task task) async {
    final newDue = await showDuePicker(
      context: context,
      initialDate: task.dueDate() != null
          ? DateTime.parse(task.dueDate()!)
          : DateTime.now(),
    );
    if (!context.mounted) return;
    if (newDue == null) return;
    EasyLoading.show(status: L10n.of(context).updatingDue);
    try {
      final updater = task.updateBuilder();
      updater.dueDate(newDue.due.year, newDue.due.month, newDue.due.day);
      if (newDue.includeTime) {
        final seconds = newDue.due.hour * 60 * 60 +
            newDue.due.minute * 60 +
            newDue.due.second;
        // adapt the timezone value
        updater.utcDueTimeOfDay(seconds + newDue.due.timeZoneOffset.inSeconds);
      } else if (task.utcDueTimeOfDay() != null) {
        // we have one, we need to reset it
        updater.unsetUtcDueTimeOfDay();
      }
      await updater.send();
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(L10n.of(context).dueSuccess);
    } catch (e) {
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).updatingDueFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Widget _widgetTaskAssignment(BuildContext context, Task task, WidgetRef ref) {
    return ListTile(
      dense: true,
      leading: const Icon(Atlas.business_man_thin),
      title: Text(
        L10n.of(context).assignment,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      subtitle: task.isAssignedToMe()
          ? assigneeName(context, task, ref)
          : Text(
              L10n.of(context).noAssignment,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
      trailing: ActerInlineTextButton(
        onPressed: () => task.isAssignedToMe()
            ? onUnAssign(context, task)
            : onAssign(context, task),
        child: Text(
          task.isAssignedToMe()
              ? L10n.of(context).removeMyself
              : L10n.of(context).assignMyself,
        ),
      ),
    );
  }

  Widget assigneeName(
    BuildContext context,
    Task task,
    WidgetRef ref,
  ) {
    final assignees = task.assigneesStr().map((s) => s.toDartString()).toList();
    final memberData = ref.watch(
      roomMemberProvider((roomId: task.roomIdStr(), userId: assignees.first)),
    );
    return memberData.when(
      data: (data) => Text(
        data.profile.displayName ?? '',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      error: (error, stackTrace) => Text(
        L10n.of(context).errorLoading(error),
      ),
      loading: () => Skeletonizer(
        child: Text(L10n.of(context).loading),
      ),
    );
  }

  Future<void> onAssign(BuildContext context, Task task) async {
    EasyLoading.show(status: L10n.of(context).assigningSelf);
    try {
      await task.assignSelf();
      if (!context.mounted) return;
      EasyLoading.showToast(L10n.of(context).assignedYourself);
    } catch (e, st) {
      _log.severe('Failed to assign self', e, st);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).failedToAssignSelf(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> onUnAssign(
    BuildContext context,
    Task task,
  ) async {
    EasyLoading.show(status: L10n.of(context).unassigningSelf);
    try {
      await task.unassignSelf();
      if (!context.mounted) return;
      EasyLoading.showToast(L10n.of(context).assignmentWithdrawn);
    } catch (e, st) {
      _log.severe('Failed to unassign self', e, st);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).failedToUnassignSelf(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  void showEditTaskItemNameBottomSheet({
    required BuildContext context,
    required String titleValue,
    required Task task,
    required WidgetRef ref,
  }) {
    showEditTitleBottomSheet(
      context: context,
      bottomSheetTitle: L10n.of(context).editName,
      titleValue: titleValue,
      onSave: (newName) async {
        EasyLoading.show(status: L10n.of(context).updatingTask);
        final updater = task.updateBuilder();
        updater.title(newName);
        try {
          await updater.send();
          ref.invalidate(spaceTasksListsProvider);
          EasyLoading.dismiss();
          if (!context.mounted) return;
          context.pop();
        } catch (e) {
          EasyLoading.dismiss();
          if (!context.mounted) return;
          EasyLoading.showError(
            L10n.of(context).updatingTaskFailed(e),
            duration: const Duration(seconds: 3),
          );
        }
      },
    );
  }
}
