import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:acter/features/attachments/widgets/attachment_section.dart';
import 'package:acter/features/comments/widgets/comments_section.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/features/tasks/providers/tasks.dart';
import 'package:acter/features/tasks/widgets/task_entry.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TaskListCard extends ConsumerStatefulWidget {
  final TaskList taskList;
  final bool showSpace;
  final bool showTitle;
  final bool showDescription;
  final bool showAttachmentsAndComments;

  const TaskListCard({
    super.key,
    required this.taskList,
    this.showSpace = true,
    this.showTitle = true,
    this.showDescription = false,
    this.showAttachmentsAndComments = false,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TaskListCardState();
}

class _TaskListCardState extends ConsumerState<TaskListCard> {
  bool showInlineAddTask = false;
  @override
  Widget build(BuildContext context) {
    final taskList = widget.taskList;
    final tlId = taskList.eventIdStr();

    final tasks = ref.watch(tasksProvider(taskList));
    final spaceId = taskList.spaceIdStr();

    final List<Widget> body = [];
    if (widget.showTitle) {
      body.add(
        ListTile(
          title: InkWell(
            onTap: () => context.pushNamed(
              Routes.taskList.name,
              pathParameters: {'taskListId': tlId},
            ),
            child: Text(
              key: Key('task-list-title-$tlId'),
              taskList.name(),
            ),
          ),
          subtitle: widget.showSpace
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    alignment: WrapAlignment.start,
                    children: [
                      SpaceChip(spaceId: spaceId),
                    ],
                  ),
                )
              : null,
        ),
      );
    } else if (widget.showSpace) {
      body.add(
        ListTile(title: SpaceChip(spaceId: spaceId)),
      );
    }

    if (widget.showDescription) {
      final desc = taskList.description();
      if (desc != null) {
        final formattedBody = desc.formattedBody();
        if (formattedBody?.isNotEmpty == true) {
          body.add(RenderHtml(text: formattedBody!));
        } else {
          final str = desc.body();
          if (str.isNotEmpty) {
            body.add(Text(str));
          }
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Card(
        key: Key('task-list-card-$tlId'),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              ...body,
              tasks.when(
                data: (overview) {
                  List<Widget> children = [];
                  final int total =
                      overview.doneTasks.length + overview.openTasks.length;

                  if (total > 3) {
                    children.add(
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          L10n.of(context)
                              .countTasksDone(overview.doneTasks.length, total),
                        ),
                      ),
                    );
                  }

                  for (final task in overview.openTasks) {
                    children.add(
                      TaskEntry(
                        task: task,
                      ),
                    );
                  }
                  if (showInlineAddTask) {
                    children.add(
                      _InlineTaskAdd(
                        taskList: taskList,
                        cancel: () => setState(() => showInlineAddTask = false),
                      ),
                    );
                  } else {
                    children.add(
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        child: OutlinedButton(
                          key: Key('task-list-$tlId-add-task-inline'),
                          onPressed: () =>
                              {setState(() => showInlineAddTask = true)},
                          child: Text(
                            L10n.of(context).addTask,
                            style: Theme.of(context).textTheme.bodySmall!,
                          ),
                        ),
                      ),
                    );
                  }

                  for (final task in overview.doneTasks) {
                    children.add(TaskEntry(task: task));
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
                    ),
                  );
                },
                error: (error, stack) =>
                    Text(L10n.of(context).errorLoadingTasks(error)),
                loading: () => Text(L10n.of(context).loading),
              ),
              if (widget.showAttachmentsAndComments) ...[
                const SizedBox(height: 20),
                AttachmentSectionWidget(manager: taskList.attachments()),
                const SizedBox(height: 20),
                CommentsSection(manager: taskList.comments()),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineTaskAdd extends StatefulWidget {
  final Function() cancel;
  final TaskList taskList;
  const _InlineTaskAdd({required this.cancel, required this.taskList});

  @override
  _InlineTaskAddState createState() => _InlineTaskAddState();
}

class _InlineTaskAddState extends State<_InlineTaskAdd> {
  final _formKey = GlobalKey<FormState>();
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
        decoration: InputDecoration(
          prefixIcon: const Icon(Atlas.plus_circle_thin),
          focusedBorder: const UnderlineInputBorder(),
          errorBorder: const UnderlineInputBorder(),
          enabledBorder: const UnderlineInputBorder(),
          labelText: L10n.of(context).titleTheNewTask,
          suffix: IconButton(
            key: Key('task-list-$tlId-add-task-inline-cancel'),
            onPressed: widget.cancel,
            icon: const Icon(
              Atlas.xmark_circle_thin,
              size: 24,
            ),
          ),
        ),
        onFieldSubmitted: (value) {
          if (_formKey.currentState!.validate()) {
            _formKey.currentState!.save();
            _handleSubmit(context);
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return L10n.of(context).aTaskMustHaveATitle;
          }
          return null;
        },
      ),
    );
  }

  Future<void> _handleSubmit(BuildContext context) async {
    final taskDraft = widget.taskList.taskBuilder();
    taskDraft.title(_textCtrl.text);
    try {
      await taskDraft.send();
    } catch (e) {
      if (context.mounted) {
        EasyLoading.showError(
          L10n.of(context).creatingTaskFailed(e),
          duration: const Duration(seconds: 3),
        );
      }
      return;
    }
    _textCtrl.text = '';
    if (_formKey.currentContext != null) {
      Scrollable.ensureVisible(_formKey.currentContext!);
    }
    focusNode.requestFocus();
  }
}
