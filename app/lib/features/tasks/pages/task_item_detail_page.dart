import 'dart:async';

import 'package:acter/common/actions/redact_content.dart';
import 'package:acter/common/actions/report_content.dart';
import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/toolkit/errors/error_page.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/acter_icon_picker/acter_icon_widget.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/color_data.dart';
import 'package:acter/common/widgets/edit_html_description_sheet.dart';
import 'package:acter/common/widgets/edit_title_sheet.dart';
import 'package:acter/common/toolkit/html/render_html.dart';
import 'package:acter/features/attachments/types.dart';
import 'package:acter/features/attachments/widgets/attachment_section.dart';
import 'package:acter/features/comments/types.dart';
import 'package:acter/features/comments/widgets/comments_section_widget.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/features/notifications/actions/autosubscribe.dart';
import 'package:acter/features/notifications/widgets/object_notification_status.dart';
import 'package:acter/features/tasks/providers/task_items_providers.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter/features/tasks/widgets/due_picker.dart';
import 'package:acter/features/tasks/widgets/skeleton/task_item_detail_page_skeleton.dart';
import 'package:acter/features/tasks/widgets/task_status_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    return Scaffold(
      appBar: _buildAppBar(context, ref),
      body: _buildBody(context, ref),
    );
  }

  AppBar _buildAppBar(BuildContext context, WidgetRef ref) {
    final task =
        ref
            .watch(taskItemProvider((taskListId: taskListId, taskId: taskId)))
            .valueOrNull;
    if (task == null) {
      return AppBar();
    }

    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    return AppBar(
      actions: [
        ObjectNotificationStatus(objectId: taskId),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) {
            return [
              PopupMenuItem(
                onTap: () {
                  showEditTitleBottomSheet(
                    context: context,
                    bottomSheetTitle: lang.editName,
                    titleValue: task.title(),
                    onSave:
                        (ref, newName) =>
                            saveTitle(context, ref, task, newName),
                  );
                },
                child: Text(lang.editTitle, style: textTheme.bodyMedium),
              ),
              PopupMenuItem(
                onTap: () => showEditDescriptionSheet(context, task),
                child: Text(lang.editDescription, style: textTheme.bodyMedium),
              ),
              PopupMenuItem(
                onTap:
                    () => showRedactDialog(
                      context: context,
                      ref: ref,
                      task: task,
                    ),
                child: Text(lang.delete, style: textTheme.bodyMedium),
              ),
              PopupMenuItem(
                onTap: () => showReportDialog(context: context, task: task),
                child: Text(lang.report, style: textTheme.bodyMedium),
              ),
            ];
          },
        ),
      ],
    );
  }

  // Redact Task Item Dialog
  Future<void> showRedactDialog({
    required BuildContext context,
    required WidgetRef ref,
    required Task task,
  }) async {
    await openRedactContentDialog(
      context,
      title: L10n.of(context).deleteTaskItem,
      onSuccess: () => Navigator.pop(context),
      eventId: task.eventIdStr(),
      roomId: task.roomIdStr(),
      isSpace: true,
    );
  }

  // Report Task Item Dialog
  Future<void> showReportDialog({
    required BuildContext context,
    required Task task,
  }) async {
    final lang = L10n.of(context);
    await openReportContentDialog(
      context,
      title: lang.reportTaskItem,
      description: lang.reportThisContent,
      eventId: task.eventIdStr(),
      senderId: task.authorStr(),
      roomId: task.roomIdStr(),
      isSpace: true,
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final taskLoader = ref.watch(
      taskItemProvider((taskListId: taskListId, taskId: taskId)),
    );
    final errored = taskLoader.asError;
    if (errored != null) {
      _log.severe('Failed to load task', errored.error, errored.stackTrace);
      return ErrorPage(
        background: const TaskItemDetailPageSkeleton(),
        error: errored.error,
        stack: errored.stackTrace,
        onRetryTap: () {
          ref.invalidate(
            taskItemProvider((taskListId: taskListId, taskId: taskId)),
          );
        },
      );
    }

    return taskData(context, taskLoader.valueOrNull, ref);
  }

  Widget taskData(BuildContext context, Task? task, WidgetRef ref) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task != null) ...[
              const SizedBox(height: 10),
              _taskHeader(context, task, ref),
              const SizedBox(height: 10),
              _widgetTaskDate(context, ref, task),
              _widgetTaskAssignment(context, task, ref),
              ..._widgetDescription(context, task),
              const SizedBox(height: 40),
            ] else
              const TaskItemDetailPageSkeleton(),
            AttachmentSectionWidget(
              manager: task?.asAttachmentsManagerProvider(),
            ),
            const SizedBox(height: 20),
            CommentsSectionWidget(
              managerProvider: task?.asCommentsManagerProvider(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _taskHeader(BuildContext context, Task task, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final taskList = ref.watch(taskListProvider(taskListId)).valueOrNull;
    return ListTile(
      dense: true,
      leading: TaskStatusWidget(task: task, size: 40),
      title: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap:
                () => showEditTaskItemNameBottomSheet(
                  context: context,
                  task: task,
                  titleValue: task.title(),
                ),
            child: Text(task.title(), style: textTheme.titleMedium),
          ),
          if (taskList != null)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SpaceChip(spaceId: taskList.spaceIdStr(), useCompactView: true),
                const SizedBox(width: 5),
                InkWell(
                  onTap:
                      () => context.pushNamed(
                        Routes.taskListDetails.name,
                        pathParameters: {'taskListId': taskListId},
                      ),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ActerIconWidget(
                        iconSize: 22,
                        color: convertColor(
                          taskList.display()?.color(),
                          iconPickerColors[0],
                        ),
                        icon: ActerIcon.iconForTask(
                          taskList.display()?.iconStr(),
                        ),
                      ),
                      Text(taskList.name(), style: textTheme.labelMedium),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  List<Widget> _widgetDescription(BuildContext context, Task task) {
    final description = task.description();
    if (description == null) return [];
    final formattedBody = description.formattedBody();
    final textTheme = Theme.of(context).textTheme;

    return [
      const SizedBox(height: 20),
      SelectionArea(
        child: GestureDetector(
          onTap: () {
            showEditDescriptionSheet(context, task);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child:
                formattedBody != null
                    ? RenderHtml(
                      text: formattedBody,
                      defaultTextStyle: textTheme.labelLarge,
                      roomId: task.roomIdStr(),
                    )
                    : Text(description.body(), style: textTheme.labelLarge),
          ),
        ),
      ),
    ];
  }

  void showEditDescriptionSheet(BuildContext context, Task task) {
    showEditHtmlDescriptionBottomSheet(
      context: context,
      descriptionHtmlValue: task.description()?.formattedBody(),
      descriptionMarkdownValue: task.description()?.body(),
      onSave: (ref, htmlBodyDescription, plainDescription) {
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
    final lang = L10n.of(context);
    EasyLoading.show(status: lang.updatingDescription);
    try {
      final updater = task.updateBuilder();
      updater.descriptionHtml(plainDescription, htmlBodyDescription);
      await updater.send();
      await autosubscribe(ref: ref, objectId: task.eventIdStr(), lang: lang);
      EasyLoading.dismiss();
      if (context.mounted) Navigator.pop(context);
    } catch (e, s) {
      _log.severe('Failed to change description of task', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.errorUpdatingDescription(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Widget _widgetTaskDate(BuildContext context, WidgetRef ref, Task task) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    final dateText =
        task.dueDate().map((date) => taskDueDateFormat(DateTime.parse(date))) ??
        lang.noDueDate;
    return ListTile(
      dense: true,
      leading: const Padding(
        padding: EdgeInsets.only(left: 15),
        child: Icon(Atlas.calendar_date_thin),
      ),
      title: Text(lang.dueDate, style: textTheme.bodyMedium),
      trailing: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Text(dateText, style: textTheme.bodyMedium),
      ),
      onTap: () => duePickerAction(context, ref, task),
    );
  }

  Future<void> duePickerAction(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final lang = L10n.of(context);
    final newDue = await showDuePicker(
      context: context,
      initialDate:
          task.dueDate().map((date) => DateTime.parse(date)) ?? DateTime.now(),
    );
    if (!context.mounted) return;
    if (newDue == null) return;
    EasyLoading.show(status: lang.updatingDue);
    try {
      final updater = task.updateBuilder();
      updater.dueDate(newDue.due.year, newDue.due.month, newDue.due.day);
      if (newDue.includeTime) {
        final seconds =
            newDue.due.hour * 60 * 60 +
            newDue.due.minute * 60 +
            newDue.due.second;
        // adapt the timezone value
        updater.utcDueTimeOfDay(seconds + newDue.due.timeZoneOffset.inSeconds);
      } else if (task.utcDueTimeOfDay() != null) {
        // we have one, we need to reset it
        updater.unsetUtcDueTimeOfDay();
      }
      await updater.send();

      await autosubscribe(ref: ref, objectId: task.eventIdStr(), lang: lang);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(lang.dueSuccess);
    } catch (e, s) {
      _log.severe('Failed to change due date of task', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.updatingDueFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Widget _widgetTaskAssignment(BuildContext context, Task task, WidgetRef ref) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    return ListTile(
      dense: true,
      leading: const Padding(
        padding: EdgeInsets.only(left: 15),
        child: Icon(Atlas.business_man_thin),
      ),
      title: Row(
        children: [
          Text(lang.assignment, style: textTheme.bodyMedium),
          const Spacer(),
          ActerInlineTextButton(
            onPressed:
                () =>
                    task.isAssignedToMe()
                        ? onUnAssign(context, ref, task)
                        : onAssign(context, ref, task),
            child: Text(
              task.isAssignedToMe() ? lang.removeMyself : lang.assignMyself,
            ),
          ),
        ],
      ),
      subtitle:
          task.isAssignedToMe()
              ? assigneeName(context, task, ref)
              : Text(lang.noAssignment, style: textTheme.bodyMedium),
    );
  }

  Widget assigneeName(BuildContext context, Task task, WidgetRef ref) {
    final assignees = asDartStringList(task.assigneesStr());
    final roomId = task.roomIdStr();

    return Wrap(
      direction: Axis.horizontal,
      children:
          assignees.map((userId) {
            final dispName =
                ref
                    .watch(
                      memberDisplayNameProvider((
                        roomId: roomId,
                        userId: userId,
                      )),
                    )
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

  Future<void> onAssign(BuildContext context, WidgetRef ref, Task task) async {
    final lang = L10n.of(context);
    EasyLoading.show(status: lang.assigningSelf);
    try {
      await task.assignSelf();

      await autosubscribe(ref: ref, objectId: task.eventIdStr(), lang: lang);
      if (!context.mounted) return;
      EasyLoading.showToast(lang.assignedYourself);
    } catch (e, s) {
      _log.severe('Failed to self-assign task', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.failedToAssignSelf(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> onUnAssign(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final lang = L10n.of(context);
    EasyLoading.show(status: lang.unassigningSelf);
    try {
      await task.unassignSelf();

      await autosubscribe(ref: ref, objectId: task.eventIdStr(), lang: lang);
      if (!context.mounted) return;
      EasyLoading.showToast(lang.assignmentWithdrawn);
    } catch (e, s) {
      _log.severe('Failed to self-unassign task', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.failedToUnassignSelf(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  void showEditTaskItemNameBottomSheet({
    required BuildContext context,
    required String titleValue,
    required Task task,
  }) {
    showEditTitleBottomSheet(
      context: context,
      bottomSheetTitle: L10n.of(context).editName,
      titleValue: titleValue,
      onSave: (ref, newName) => saveTitle(context, ref, task, newName),
    );
  }

  void saveTitle(
    BuildContext context,
    WidgetRef ref,
    Task task,
    String newName,
  ) async {
    final lang = L10n.of(context);
    EasyLoading.show(status: lang.updatingTask);
    final updater = task.updateBuilder();
    updater.title(newName);
    try {
      await updater.send();

      await autosubscribe(ref: ref, objectId: task.eventIdStr(), lang: lang);
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
        lang.updatingTaskFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
