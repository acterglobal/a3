import 'package:acter/common/actions/redact_content.dart';
import 'package:acter/common/actions/report_content.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/errors/error_page.dart';
import 'package:acter/common/widgets/acter_icon_picker/acter_icon_widget.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/color_data.dart';
import 'package:acter/common/widgets/edit_html_description_sheet.dart';
import 'package:acter/common/widgets/edit_title_sheet.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:acter/features/attachments/widgets/attachment_section.dart';
import 'package:acter/features/comments/widgets/comments_section.dart';
import 'package:acter/features/tasks/actions/update_tasklist.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter/features/tasks/widgets/task_items_list_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::tasks::tasklist_details');

class TaskListDetailPage extends ConsumerStatefulWidget {
  static const pageKey = Key('task-list-details-page');
  static const taskListTitleKey = Key('task-list-title');
  final String taskListId;

  const TaskListDetailPage({
    Key key = pageKey,
    required this.taskListId,
  }) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TaskListPageState();
}

class _TaskListPageState extends ConsumerState<TaskListDetailPage> {
  ValueNotifier<bool> showCompletedTask = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppbar() {
    final lang = L10n.of(context);
    final tasklistLoader = ref.watch(taskListItemProvider(widget.taskListId));
    return tasklistLoader.when(
      data: (tasklist) {
        final membership = ref
            .watch(roomMembershipProvider(tasklist.spaceIdStr()))
            .valueOrNull;
        bool canPost = membership?.canString('CanPostTaskList') == true;
        return AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ActerIconWidget(
                iconSize: 40,
                color: convertColor(
                  tasklist.display()?.color(),
                  iconPickerColors[0],
                ),
                icon: ActerIcon.iconForTask(
                  tasklist.display()?.iconStr(),
                ),
                onIconSelection: canPost
                    ? (color, acterIcon) {
                        updateTaskListIcon(
                          context,
                          ref,
                          tasklist,
                          color,
                          acterIcon,
                        );
                      }
                    : null,
              ),
              const SizedBox(width: 10),
              SelectionArea(
                child: GestureDetector(
                  onTap: () => showEditTaskListNameBottomSheet(
                    context: context,
                    ref: ref,
                    taskList: tasklist,
                    titleValue: tasklist.name(),
                  ),
                  child: Text(
                    key: TaskListDetailPage.taskListTitleKey,
                    tasklist.name(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) {
                return [
                  PopupMenuItem(
                    onTap: () => showEditDescriptionSheet(tasklist),
                    child: Text(
                      lang.editDescription,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  PopupMenuItem(
                    onTap: () => showRedactDialog(taskList: tasklist),
                    child: Text(
                      lang.delete,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  PopupMenuItem(
                    onTap: () => showReportDialog(tasklist),
                    child: Text(
                      lang.report,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ];
              },
            ),
          ],
        );
      },
      error: (e, s) {
        _log.severe('Failed to load tasklist', e, s);
        return AppBar(
          title: Text(lang.loadingFailed(e)),
        );
      },
      loading: () => AppBar(
        title: Text(lang.loading),
      ),
    );
  }

  // Redact Task List Dialog
  void showRedactDialog({required TaskList taskList}) {
    openRedactContentDialog(
      context,
      title: L10n.of(context).deleteTaskList,
      onSuccess: () => Navigator.pop(context),
      eventId: taskList.eventIdStr(),
      roomId: taskList.spaceIdStr(),
      isSpace: true,
    );
  }

  // Report Task List Dialog
  void showReportDialog(TaskList taskList) {
    final lang = L10n.of(context);
    openReportContentDialog(
      context,
      title: lang.reportTaskList,
      description: lang.reportThisContent,
      eventId: taskList.eventIdStr(),
      senderId: taskList.role() ?? '',
      roomId: taskList.spaceIdStr(),
      isSpace: true,
    );
  }

  Widget _buildBody() {
    final lang = L10n.of(context);
    final tasklistLoader = ref.watch(taskListItemProvider(widget.taskListId));
    return tasklistLoader.when(
      data: (tasklist) => _buildTaskListData(tasklist),
      error: (error, stack) {
        _log.severe('Failed to load tasklist', error, stack);
        return ErrorPage(
          background: Text(lang.loading),
          error: error,
          stack: stack,
          onRetryTap: () {
            ref.invalidate(taskListItemProvider(widget.taskListId));
          },
        );
      },
      loading: () => Text(lang.loading),
    );
  }

  Widget _buildTaskListData(TaskList taskListData) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _widgetDescription(taskListData),
            _widgetTasksList(taskListData),
          ],
        ),
      ),
    );
  }

  Widget _widgetDescription(TaskList taskListData) {
    final description = taskListData.description();
    if (description == null) return const SizedBox.shrink();
    final formattedBody = description.formattedBody();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectionArea(
          child: GestureDetector(
            onTap: () {
              showEditDescriptionSheet(taskListData);
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
        ),
        const SizedBox(height: 10),
        const Divider(indent: 10, endIndent: 18),
        const SizedBox(height: 10),
      ],
    );
  }

  void showEditDescriptionSheet(TaskList taskListData) {
    showEditHtmlDescriptionBottomSheet(
      context: context,
      descriptionHtmlValue: taskListData.description()?.formattedBody(),
      descriptionMarkdownValue: taskListData.description()?.body(),
      onSave: (htmlBodyDescription, plainDescription) {
        _saveDescription(taskListData, htmlBodyDescription, plainDescription);
      },
    );
  }

  Future<void> _saveDescription(
    TaskList taskListData,
    String htmlBodyDescription,
    String plainDescription,
  ) async {
    final lang = L10n.of(context);
    EasyLoading.show(status: lang.updatingDescription);
    try {
      final updater = taskListData.updateBuilder();
      updater.descriptionHtml(plainDescription, htmlBodyDescription);
      await updater.send();
      EasyLoading.dismiss();
      if (mounted) Navigator.pop(context);
    } catch (e, s) {
      _log.severe('Failed to update description of tasklist', e, s);
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.errorUpdatingDescription(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Widget _widgetTasksList(TaskList taskListData) {
    return Column(
      children: [
        _widgetTasksListHeader(),
        ValueListenableBuilder(
          valueListenable: showCompletedTask,
          builder: (context, value, child) {
            return TaskItemsListWidget(
              taskList: taskListData,
              showCompletedTask: value,
            );
          },
        ),
        const SizedBox(height: 20),
        AttachmentSectionWidget(manager: taskListData.attachments()),
        const SizedBox(height: 20),
        CommentsSection(manager: taskListData.comments()),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _widgetTasksListHeader() {
    final lang = L10n.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          lang.tasks,
        ),
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
      ],
    );
  }

  void showEditTaskListNameBottomSheet({
    required BuildContext context,
    required String titleValue,
    required TaskList taskList,
    required WidgetRef ref,
  }) {
    showEditTitleBottomSheet(
      context: context,
      bottomSheetTitle: L10n.of(context).editName,
      titleValue: titleValue,
      onSave: (newName) => updateTaskListTitle(context, taskList, newName),
    );
  }
}
