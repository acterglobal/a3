import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/features/tasks/providers/tasks.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/features/tasks/widgets/task_entry.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/material.dart';

class TaskListCard extends ConsumerStatefulWidget {
  final TaskList taskList;
  final bool showSpace;
  const TaskListCard({Key? key, required this.taskList, this.showSpace = true})
      : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TaskListCardState();
}

class _TaskListCardState extends ConsumerState<TaskListCard> {
  bool showInlineAddTask = false;
  @override
  Widget build(BuildContext context) {
    final taskList = widget.taskList;

    final tasks = ref.watch(tasksProvider(taskList));
    final spaceId = taskList.spaceIdStr();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              ListTile(
                title: Text(
                  taskList.name(),
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
                          '${overview.doneTasks.length} / $total Tasks done',
                        ),
                      ),
                    );
                  }

                  for (final task in overview.openTasks) {
                    children.add(TaskEntry(task: task));
                  }
                  if (showInlineAddTask) {
                    children.add(
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        child: _InlineTaskAdd(
                          taskList: taskList,
                          cancel: () =>
                              setState(() => showInlineAddTask = false),
                        ),
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
                          onPressed: () =>
                              {setState(() => showInlineAddTask = true)},
                          child: const Text('Add Task'),
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
                error: (error, stack) => Text('error loading tasks: $error'),
                loading: () => const Text('loading'),
              ),
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
  const _InlineTaskAdd({Key? key, required this.cancel, required this.taskList})
      : super(key: key);

  @override
  _InlineTaskAddState createState() => _InlineTaskAddState();
}

class _InlineTaskAddState extends State<_InlineTaskAdd> {
  final _formKey = GlobalKey<FormState>();
  final _textCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              autofocus: true,
              controller: _textCtrl,
              decoration: const InputDecoration(
                icon: Icon(Atlas.plus_circle_thin),
                border: UnderlineInputBorder(),
                labelText: 'Title the new task..',
              ),
              onFieldSubmitted: (value) {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  _handleSubmit(context);
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'A task must have a title';
                }
                return null;
              },
            ),
          ),
          IconButton(
            onPressed: widget.cancel,
            icon: const Icon(
              Atlas.xmark_circle_thin,
            ),
          ),
        ],
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
        customMsgSnackbar(context, 'Creating Task failed: $e');
      }
      return;
    }
    _textCtrl.text = '';
  }
}
