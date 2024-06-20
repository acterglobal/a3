import 'package:acter/common/widgets/edit_html_description_sheet.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:acter/common/widgets/edit_title_sheet.dart';
import 'package:acter/features/attachments/widgets/attachment_section.dart';
import 'package:acter/features/comments/widgets/comments_section.dart';
import 'package:acter/features/tasks/providers/tasklists.dart';
import 'package:acter/features/tasks/widgets/task_items_list_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::tasks::task_list_details_page');

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
    final taskList = ref.watch(taskListProvider(widget.taskListId));

    return taskList.when(
      data: (d) => AppBar(
        title: GestureDetector(
          onTap: () => showEditTaskListNameBottomSheet(
            context: context,
            ref: ref,
            taskList: d,
            titleValue: d.name(),
          ),
          child: Text(
            key: TaskListDetailPage.taskListTitleKey,
            d.name(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  onTap: () => showEditDescriptionSheet(d),
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
      loading: () => AppBar(
        title: Text(L10n.of(context).loading),
      ),
    );
  }

  Widget _buildBody() {
    final taskList = ref.watch(taskListProvider(widget.taskListId));
    return taskList.when(
      data: (data) => _buildTaskListData(data),
      error: (e, s) => Text(L10n.of(context).failedToLoad(e)),
      loading: () => Text(L10n.of(context).loading),
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
        GestureDetector(
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
    EasyLoading.show(status: L10n.of(context).updatingDescription);
    try {
      final updater = taskListData.updateBuilder();
      updater.descriptionHtml(plainDescription, htmlBodyDescription);
      await updater.send();
      EasyLoading.dismiss();
      if (mounted) context.pop();
    } catch (e, st) {
      _log.severe('Failed to update event description', e, st);
      EasyLoading.dismiss();
      if (!mounted) return;
      EasyLoading.showError(
        L10n.of(context).errorUpdatingDescription(e),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          L10n.of(context).tasks,
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
      onSave: (newName) async {
        EasyLoading.show(status: L10n.of(context).updatingTask);
        final updater = taskList.updateBuilder();
        updater.name(newName);
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
