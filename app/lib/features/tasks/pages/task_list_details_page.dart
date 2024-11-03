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
import 'package:acter/features/comments/widgets/comments_section_widget.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
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
import 'package:skeletonizer/skeletonizer.dart';

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
    final textTheme = Theme.of(context).textTheme;
    final tasklist =
        ref.watch(taskListItemProvider(widget.taskListId)).valueOrNull;
    final actions = List<Widget>.empty(growable: true);
    if (tasklist != null) {
      actions.addAll(
        [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) {
              return [
                // FIXME: check permissions for all theses
                PopupMenuItem(
                  onTap: () => showEditDescriptionSheet(tasklist),
                  child: Text(
                    lang.editDescription,
                    style: textTheme.bodyMedium,
                  ),
                ),
                PopupMenuItem(
                  onTap: () => showRedactDialog(taskList: tasklist),
                  child: Text(
                    lang.delete,
                    style: textTheme.bodyMedium,
                  ),
                ),
                PopupMenuItem(
                  onTap: () => showReportDialog(tasklist),
                  child: Text(
                    lang.report,
                    style: textTheme.bodyMedium,
                  ),
                ),
              ];
            },
          ),
        ],
      );
    }
    return AppBar(actions: actions);
  }

  // Redact Task List Dialog
  Future<void> showRedactDialog({required TaskList taskList}) async {
    await openRedactContentDialog(
      context,
      title: L10n.of(context).deleteTaskList,
      onSuccess: () => Navigator.pop(context),
      eventId: taskList.eventIdStr(),
      roomId: taskList.spaceIdStr(),
      isSpace: true,
    );
  }

  // Report Task List Dialog
  Future<void> showReportDialog(TaskList taskList) async {
    final lang = L10n.of(context);
    await openReportContentDialog(
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
    final tasklistLoader = ref.watch(taskListItemProvider(widget.taskListId));
    return tasklistLoader.when(
      data: (tasklist) => _buildTaskListData(tasklist),
      error: (error, stack) {
        _log.severe('Failed to load tasklist', error, stack);
        return ErrorPage(
          background: _loadingSkeleton(),
          error: error,
          stack: stack,
          onRetryTap: () {
            ref.invalidate(taskListItemProvider(widget.taskListId));
          },
        );
      },
      loading: () => _loadingSkeleton(),
      skipLoadingOnReload: true, // don't refresh to weirdly
    );
  }

  Widget _buildTaskListData(TaskList taskListData) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _taskListHeader(taskListData),
            const SizedBox(height: 20),
            _widgetDescription(taskListData),
            const SizedBox(height: 30),
            _widgetTasksListHeader(),
            ValueListenableBuilder(
              valueListenable: showCompletedTask,
              builder: (context, value, child) => TaskItemsListWidget(
                taskList: taskListData,
                showCompletedTask: value,
              ),
            ),
            const SizedBox(height: 20),
            AttachmentSectionWidget(manager: taskListData.attachments()),
            const SizedBox(height: 20),
            CommentsSectionWidget(manager: taskListData.comments()),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _taskListHeader(TaskList tasklist) {
    final textTheme = Theme.of(context).textTheme;
    final canPost = ref
            .watch(roomMembershipProvider(tasklist.spaceIdStr()))
            .valueOrNull
            ?.canString('CanPostTaskList') ==
        true;
    return ListTile(
      leading: ActerIconWidget(
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
      title: SelectionArea(
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
            style: textTheme.titleMedium,
          ),
        ),
      ),
      subtitle: SpaceChip(spaceId: tasklist.spaceIdStr(), useCompactView: true),
    );
  }

  Widget _widgetDescription(TaskList taskListData) {
    final description = taskListData.description();
    if (description == null) return const SizedBox.shrink();
    final formattedBody = description.formattedBody();
    final textTheme = Theme.of(context).textTheme;

    return SelectionArea(
      child: GestureDetector(
        onTap: () {
          showEditDescriptionSheet(taskListData);
        },
        child: formattedBody != null
            ? RenderHtml(
                text: formattedBody,
                defaultTextStyle: textTheme.labelLarge,
              )
            : Text(
                description.body(),
                style: textTheme.labelLarge,
              ),
      ),
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

  Widget _widgetTasksListHeader() {
    final lang = L10n.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          lang.tasks,
          style: Theme.of(context).textTheme.titleSmall,
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
              label: Text(value ? lang.hideCompleted : lang.showCompleted),
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

  Widget _loadingSkeleton() => Skeletonizer.zone(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Bone.icon(size: 40),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Task List Title',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SpaceChip.loadingCompact(),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Task description'),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  L10n.of(context).tasks,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Bone.iconButton(
                  size: 18,
                ),
              ],
            ),
            TaskItemsListWidget.loading(),
            const SizedBox(height: 20),
            AttachmentSectionWidget.loading(),
            const SizedBox(height: 20),
            CommentsSectionWidget.loading(),
            const SizedBox(height: 20),
          ],
        ),
      );
}
