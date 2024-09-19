import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/tasks/models/tasks.dart';
import 'package:acter/features/tasks/providers/task_items_providers.dart';
import 'package:acter/features/tasks/sheets/create_update_task_item.dart';
import 'package:acter/features/tasks/widgets/skeleton/task_items_skeleton.dart';
import 'package:acter/features/tasks/widgets/task_item.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::tasks::widgets::list');

class TaskItemsListWidget extends ConsumerStatefulWidget {
  final TaskList taskList;
  final bool showCompletedTask;

  const TaskItemsListWidget({
    super.key,
    required this.taskList,
    this.showCompletedTask = false,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      TaskItemsListWidgetState();
}

class TaskItemsListWidgetState extends ConsumerState<TaskItemsListWidget> {
  final ValueNotifier<bool> showInlineAddTask = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    final overviewLoader = ref.watch(taskItemsListProvider(widget.taskList));
    return overviewLoader.when(
      data: (overview) => taskData(context, overview),
      error: (e, s) {
        _log.severe('Failed to load tasklist', e, s);
        return Text(L10n.of(context).errorLoadingTasks(e));
      },
      loading: () => const TaskItemsSkeleton(),
    );
  }

  Widget taskData(BuildContext context, TasksOverview overview) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        openTasksEntries(context, overview),
        inlineAddTask(),
        doneTasksEntries(context, overview),
      ],
    );
  }

  Widget openTasksEntries(BuildContext context, TasksOverview overview) {
    if (overview.openTasks.isEmpty) {
      return const SizedBox.shrink();
    }
    final taskListId = widget.taskList.eventIdStr();
    return Column(
      children: [
        for (final taskId in overview.openTasks)
          TaskItem(
            onTap: () => showInlineAddTask.value = false,
            taskListId: taskListId,
            taskId: taskId,
          ),
      ],
    );
  }

  Widget inlineAddTask() {
    final taskListId = widget.taskList.eventIdStr();
    return ValueListenableBuilder(
      valueListenable: showInlineAddTask,
      builder: (context, value, child) {
        return value
            ? _InlineTaskAdd(
                taskList: widget.taskList,
                cancel: () => showInlineAddTask.value = false,
              )
            : Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: ActerInlineTextButton(
                  key: Key('task-list-$taskListId-add-task-inline'),
                  onPressed: () => showInlineAddTask.value = true,
                  child: Text(L10n.of(context).addTask),
                ),
              );
      },
    );
  }

  Widget doneTasksEntries(BuildContext context, TasksOverview overview) {
    if (overview.doneTasks.isEmpty || !widget.showCompletedTask) {
      return const SizedBox.shrink();
    }
    final taskListId = widget.taskList.eventIdStr();
    return Column(
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            const Expanded(
              child: Divider(
                indent: 20,
                endIndent: 20,
              ),
            ),
            Text(
              L10n.of(context).countTasksCompleted(overview.doneTasks.length),
            ),
            const Expanded(
              child: Divider(
                indent: 20,
                endIndent: 20,
              ),
            ),
          ],
        ),
        for (final taskId in overview.doneTasks)
          TaskItem(
            taskListId: taskListId,
            taskId: taskId,
            onTap: () => showInlineAddTask.value = false,
          ),
      ],
    );
  }
}

class _InlineTaskAdd extends StatefulWidget {
  final Function() cancel;
  final TaskList taskList;

  const _InlineTaskAdd({
    required this.cancel,
    required this.taskList,
  });

  @override
  _InlineTaskAddState createState() => _InlineTaskAddState();
}

class _InlineTaskAddState extends State<_InlineTaskAdd> {
  final _formKey = GlobalKey<FormState>(debugLabel: 'inline task form');
  final _textCtrl = TextEditingController();
  final FocusNode focusNode = FocusNode();

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tlId = widget.taskList.eventIdStr();
    return Form(
      key: _formKey,
      child: TextFormField(
        key: Key('task-list-$tlId-add-task-inline-txt'),
        focusNode: focusNode,
        autofocus: true,
        controller: _textCtrl,
        textInputAction: TextInputAction.send,
        decoration: InputDecoration(
          prefixIcon: const Icon(Atlas.plus_circle_thin),
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          hintText: L10n.of(context).titleTheNewTask,
          suffix: IconButton(
            onPressed: () => showCreateUpdateTaskItemBottomSheet(
              context,
              taskList: widget.taskList,
              taskName: _textCtrl.text,
              cancel: widget.cancel,
            ),
            padding: EdgeInsets.zero,
            icon: const Icon(
              Atlas.arrows_up_right_down_left,
              size: 18,
            ),
          ),
          suffixIcon: IconButton(
            key: Key('task-list-$tlId-add-task-inline-cancel'),
            onPressed: widget.cancel,
            icon: const Icon(
              Atlas.xmark_circle_thin,
              size: 24,
            ),
          ),
        ),
        onFieldSubmitted: (value) {
          final curState = _formKey.currentState;
          if (curState == null) throw 'Form state not available';
          if (curState.validate()) {
            curState.save();
            _handleSubmit(context);
          }
        },
        // required field, space not allowed
        validator: (val) => val == null || val.trim().isEmpty
            ? L10n.of(context).aTaskMustHaveATitle
            : null,
      ),
    );
  }

  Future<void> _handleSubmit(BuildContext context) async {
    final taskDraft = widget.taskList.taskBuilder();
    taskDraft.title(_textCtrl.text);
    try {
      await taskDraft.send();
    } catch (e, s) {
      _log.severe('Failed to change title of tasklist', e, s);
      if (!context.mounted) return;
      EasyLoading.showError(
        L10n.of(context).updatingTaskFailed(e),
        duration: const Duration(seconds: 3),
      );
      return;
    }
    _textCtrl.text = '';
    _formKey.currentContext.let((p0) => Scrollable.ensureVisible(p0));
    focusNode.requestFocus();
  }
}
