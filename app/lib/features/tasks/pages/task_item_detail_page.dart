import 'dart:async';

import 'package:acter/common/actions/redact_content.dart';
import 'package:acter/common/actions/report_content.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/toolkit/errors/error_page.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/edit_html_description_sheet.dart';
import 'package:acter/common/widgets/edit_title_sheet.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:acter/features/attachments/widgets/attachment_section.dart';
import 'package:acter/features/comments/widgets/comments_section.dart';
import 'package:acter/features/tasks/providers/task_items_providers.dart';
import 'package:acter/features/tasks/widgets/due_picker.dart';
import 'package:acter/features/tasks/widgets/skeleton/task_item_detail_page_skeleton.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::tasks::task_item_details');

class TaskItemDetailPage extends ConsumerWidget {
  final String taskListId;
  final String taskId;

  const TaskItemDetailPage({
    required this.taskListId,
    required this.taskId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskLoader =
        ref.watch(taskItemProvider((taskListId: taskListId, taskId: taskId)));
    return Scaffold(
      appBar: _buildAppBar(context, ref, taskLoader),
      body: _buildBody(context, ref, taskLoader),
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Task> taskLoader,
  ) {
    return taskLoader.when(
      data: (task) => AppBar(
        title: SelectionArea(
          child: GestureDetector(
            onTap: () => showEditTaskItemNameBottomSheet(
              context: context,
              ref: ref,
              task: task,
              titleValue: task.title(),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.list,
                      color: Colors.white54,
                      size: 22,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      L10n.of(context).taskList,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  onTap: () {
                    showEditTitleBottomSheet(
                      context: context,
                      bottomSheetTitle: L10n.of(context).editName,
                      titleValue: task.title(),
                      onSave: (newName) =>
                          saveTitle(context, ref, task, newName),
                    );
                  },
                  child: Text(
                    L10n.of(context).editTitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                PopupMenuItem(
                  onTap: () => showEditDescriptionSheet(context, ref, task),
                  child: Text(
                    L10n.of(context).editDescription,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                PopupMenuItem(
                  onTap: () => showRedactDialog(
                    context: context,
                    ref: ref,
                    task: task,
                  ),
                  child: Text(
                    L10n.of(context).delete,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                PopupMenuItem(
                  onTap: () => showReportDialog(context: context, task: task),
                  child: Text(
                    L10n.of(context).report,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      error: (e, s) {
        _log.severe('Failed to load task', e, s);
        return AppBar(
          title: Text(L10n.of(context).loadingFailed(e)),
        );
      },
      loading: () => AppBar(
        title: Text(L10n.of(context).loading),
      ),
    );
  }

  // Redact Task Item Dialog
  void showRedactDialog({
    required BuildContext context,
    required WidgetRef ref,
    required Task task,
  }) {
    openRedactContentDialog(
      context,
      title: L10n.of(context).deleteTaskItem,
      onSuccess: () {
        Navigator.pop(context);
      },
      eventId: task.eventIdStr(),
      roomId: task.roomIdStr(),
      isSpace: true,
    );
  }

  // Report Task Item Dialog
  void showReportDialog({
    required BuildContext context,
    required Task task,
  }) {
    openReportContentDialog(
      context,
      title: L10n.of(context).reportTaskItem,
      description: L10n.of(context).reportThisContent,
      eventId: task.eventIdStr(),
      senderId: task.authorStr(),
      roomId: task.roomIdStr(),
      isSpace: true,
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Task> taskLoader,
  ) {
    return taskLoader.when(
      data: (task) => taskData(context, task, ref),
      error: (error, stack) {
        _log.severe('Failed to load task', error, stack);
        return ErrorPage(
          background: const TaskItemDetailPageSkeleton(),
          error: error,
          stack: stack,
          onRetryTap: () {
            ref.invalidate(
              taskItemProvider((taskListId: taskListId, taskId: taskId)),
            );
          },
        );
      },
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
            const SizedBox(height: 10),
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
    return description.let(
          (p0) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectionArea(
                child: GestureDetector(
                  onTap: () {
                    showEditDescriptionSheet(context, ref, task);
                  },
                  child: p0.formattedBody().let(
                            (p1) => RenderHtml(
                              text: p1,
                              defaultTextStyle:
                                  Theme.of(context).textTheme.labelLarge,
                            ),
                          ) ??
                      Text(
                        p0.body(),
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ) ??
        const SizedBox.shrink();
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
      if (context.mounted) Navigator.pop(context);
    } catch (e, s) {
      _log.severe('Failed to change description of task', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).errorUpdatingDescription(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Widget _widgetTaskDate(BuildContext context, Task task) {
    return ListTile(
      dense: true,
      leading: const Icon(Atlas.calendar_date_thin),
      title: Text(
        L10n.of(context).dueDate,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Text(
          task.dueDate().let((p0) => taskDueDateFormat(DateTime.parse(p0))) ??
              L10n.of(context).noDueDate,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      onTap: () => duePickerAction(context, task),
    );
  }

  Future<void> duePickerAction(BuildContext context, Task task) async {
    final newDue = await showDuePicker(
      context: context,
      initialDate:
          task.dueDate().let((p0) => DateTime.parse(p0)) ?? DateTime.now(),
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
    } catch (e, s) {
      _log.severe('Failed to change due date of task', e, s);
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
      title: Row(
        children: [
          Text(
            L10n.of(context).assignment,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Spacer(),
          ActerInlineTextButton(
            onPressed: () => task.isAssignedToMe()
                ? onUnAssign(context, task)
                : onAssign(context, task),
            child: Text(
              task.isAssignedToMe()
                  ? L10n.of(context).removeMyself
                  : L10n.of(context).assignMyself,
            ),
          ),
        ],
      ),
      subtitle: task.isAssignedToMe()
          ? assigneeName(context, task, ref)
          : Text(
              L10n.of(context).noAssignment,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
    );
  }

  Widget assigneeName(BuildContext context, Task task, WidgetRef ref) {
    final assignees = asDartStringList(task.assigneesStr());
    final roomId = task.roomIdStr();

    return Wrap(
      direction: Axis.horizontal,
      children: assignees.map((userId) {
        final dispName = ref
            .watch(memberDisplayNameProvider((roomId: roomId, userId: userId)))
            .valueOrNull;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Chip(
            labelPadding: EdgeInsets.zero,
            label: Text(
              dispName ?? userId,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> onAssign(BuildContext context, Task task) async {
    EasyLoading.show(status: L10n.of(context).assigningSelf);
    try {
      await task.assignSelf();
      if (!context.mounted) return;
      EasyLoading.showToast(L10n.of(context).assignedYourself);
    } catch (e, s) {
      _log.severe('Failed to self-assign task', e, s);
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

  Future<void> onUnAssign(BuildContext context, Task task) async {
    EasyLoading.show(status: L10n.of(context).unassigningSelf);
    try {
      await task.unassignSelf();
      if (!context.mounted) return;
      EasyLoading.showToast(L10n.of(context).assignmentWithdrawn);
    } catch (e, s) {
      _log.severe('Failed to self-unassign task', e, s);
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
      onSave: (newName) => saveTitle(context, ref, task, newName),
    );
  }

  void saveTitle(
    BuildContext context,
    WidgetRef ref,
    Task task,
    String newName,
  ) async {
    EasyLoading.show(status: L10n.of(context).updatingTask);
    final updater = task.updateBuilder();
    updater.title(newName);
    try {
      await updater.send();
      EasyLoading.dismiss();
      if (!context.mounted) return;
      Navigator.pop(context);
    } catch (e, s) {
      _log.severe('Failed to change title of task', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).updatingTaskFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
