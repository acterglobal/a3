import 'dart:async';

import 'package:acter/common/actions/redact_content.dart';
import 'package:acter/common/actions/report_content.dart';
import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/toolkit/buttons/user_chip.dart';
import 'package:acter/common/toolkit/errors/error_page.dart';
import 'package:acter/common/toolkit/html/render_html.dart';
import 'package:acter/common/toolkit/menu_item_widget.dart';
import 'package:acter/router/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/acter_icon_picker/acter_icon_widget.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/color_data.dart';
import 'package:acter/common/widgets/edit_html_description_sheet.dart';
import 'package:acter/common/widgets/edit_title_sheet.dart';
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
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:acter/features/tasks/actions/add_task.dart';

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

    final task = taskLoader.valueOrNull;
    if (task == null) {
      return Scaffold(
        appBar: AppBar(),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TaskItemDetailPageSkeleton(),
                AttachmentSectionWidget(manager: null),
                const SizedBox(height: 20),
                CommentsSectionWidget(managerProvider: null),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );
    }

    return _TaskItemBody(taskListId: taskListId, task: task);
  }
}

class _TaskItemBody extends ConsumerWidget {
  final String taskListId;
  final Task task;

  const _TaskItemBody({required this.taskListId, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: _buildAppBar(context, ref),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _taskHeader(context, ref),
              const SizedBox(height: 10),
              _widgetTaskDate(context, ref),
              _widgetTaskAssignment(context, ref),
              ..._widgetDescription(context),
              const SizedBox(height: 40),
              AttachmentSectionWidget(
                manager: task.asAttachmentsManagerProvider(),
              ),
              const SizedBox(height: 20),
              CommentsSectionWidget(
                managerProvider: task.asCommentsManagerProvider(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    return AppBar(
      actions: [
        ObjectNotificationStatus(objectId: task.eventIdStr()),
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
                onTap: () => showEditDescriptionSheet(context),
                child: Text(lang.editDescription, style: textTheme.bodyMedium),
              ),
              PopupMenuItem(
                onTap: () => showRedactDialog(context: context, ref: ref),
                child: Text(lang.delete, style: textTheme.bodyMedium),
              ),
              PopupMenuItem(
                onTap: () => showReportDialog(context: context),
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
  Future<void> showReportDialog({required BuildContext context}) async {
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

  Widget _taskHeader(BuildContext context, WidgetRef ref) {
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

  List<Widget> _widgetDescription(BuildContext context) {

    // Check if migration is needed
    final description = task.description();
    migrateTaskDescription(task);
    if (description == null) return [];
    final formattedBody = description.formattedBody();
    final textTheme = Theme.of(context).textTheme;

    return [
      const SizedBox(height: 20),
      SelectionArea(
        child: GestureDetector(
          onTap: () {
            showEditDescriptionSheet(context);
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

  void showEditDescriptionSheet(BuildContext context) {
    final description = task.description();
    showEditHtmlDescriptionBottomSheet(
      context: context,
      descriptionHtmlValue: description?.formattedBody() ?? '',
      descriptionMarkdownValue: description?.body() ?? '',
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

  Widget _widgetTaskDate(BuildContext context, WidgetRef ref) {
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
      onTap: () => duePickerAction(context, ref),
    );
  }

  Future<void> duePickerAction(BuildContext context, WidgetRef ref) async {
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

  Future<void> assigneesAction(BuildContext context, WidgetRef ref) async {
    final lang = L10n.of(context);
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      enableDrag: true,
      useSafeArea: true,
      isScrollControlled: true,
      isDismissible: true,
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  title: Text(L10n.of(context).assignment),
                ),
                const SizedBox(height: 10),
                if (task.isAssignedToMe())
                  MenuItemWidget(
                    onTap: () {
                      onUnAssign(context, ref);
                      Navigator.pop(context);
                    },
                    title: lang.removeYourself,
                    titleStyles: Theme.of(context).textTheme.bodyMedium,
                    iconData: PhosphorIconsLight.x,
                    withMenu: false,
                    iconColor: Theme.of(context).colorScheme.error,
                  )
                else
                  MenuItemWidget(
                    onTap: () {
                      onAssign(context, ref);
                      Navigator.pop(context);
                    },
                    title: lang.assignYourself,
                    titleStyles: Theme.of(context).textTheme.bodyMedium,
                    iconData: PhosphorIconsLight.plus,
                    withMenu: false,
                  ),
              ],
            ),
          ),
    );
  }

  Widget _widgetTaskAssignment(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    final assignees = asDartStringList(task.assigneesStr());
    final hasAssignees = assignees.isNotEmpty;
    return ListTile(
      onTap: () => assigneesAction(context, ref),
      dense: true,
      leading: const Padding(
        padding: EdgeInsets.only(left: 15),
        child: Icon(Atlas.business_man_thin),
      ),
      title:
          hasAssignees
              ? Text(lang.assignment, style: textTheme.bodySmall)
              : Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text(
                  lang.notAssigned,
                  style: textTheme.bodyMedium?.copyWith(
                    decoration: TextDecoration.underline,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
      subtitle:
          hasAssignees
              ? buildAssignees(context, assignees, task.roomIdStr(), ref)
              : null,
      trailing:
          hasAssignees
              ? InkWell(
                onTap: () => assigneesAction(context, ref),
                child: const Icon(Icons.more_vert),
              )
              : null,
    );
  }

  Widget buildAssignees(
    BuildContext context,
    List<String> assignees,
    String roomId,
    WidgetRef ref,
  ) {
    return Wrap(
      direction: Axis.horizontal,
      spacing: 5,
      children:
          assignees
              .map(
                (memberId) => UserChip(
                  roomId: roomId,
                  memberId: memberId,
                  style: Theme.of(context).textTheme.bodyLarge,
                  onTap:
                      (
                        context, {
                        required bool isMe,
                        required VoidCallback defaultOnTap,
                      }) => isMe ? onUnAssign(context, ref) : defaultOnTap(),
                  trailingBuilder:
                      (context, {bool isMe = false, double fontSize = 12}) =>
                          isMe
                              ? Icon(PhosphorIconsLight.x, size: fontSize)
                              : null,
                ),
              )
              .toList(),
    );
  }

  Future<void> onAssign(BuildContext context, WidgetRef ref) async {
    final lang = L10n.of(context);
    EasyLoading.show(status: lang.assigningSelf);
    try {
      await task.assignSelf();

      await autosubscribe(ref: ref, objectId: task.eventIdStr(), lang: lang);
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

  Future<void> onUnAssign(BuildContext context, WidgetRef ref) async {
    final lang = L10n.of(context);
    EasyLoading.show(status: lang.unassigningSelf);
    try {
      await task.unassignSelf();

      await autosubscribe(ref: ref, objectId: task.eventIdStr(), lang: lang);
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
