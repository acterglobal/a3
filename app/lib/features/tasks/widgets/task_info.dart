import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/widgets/md_editor_with_preview.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:acter/common/widgets/user_chip.dart';
import 'package:acter/features/tasks/widgets/due_chip.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'dart:core';

class TaskInfo extends ConsumerWidget {
  static const statusBtnNotDone = Key('task-info-status-not-done');
  static const statusBtnDone = Key('task-info-status-done');
  static const titleField = Key('task-title');
  static const dueDateField = Key('task-due-field');
  static const assignmentsFields = Key('task-assignments');
  static const selfAssignKey = Key('task-self-assign');
  static const selfUnassignKey = Key('task-self-unassign');
  final Task task;
  const TaskInfo({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDone = task.isDone();

    return Column(
      children: [
        Card(
          child: Column(
            children: [
              ListTile(
                leading: InkWell(
                  key: isDone ? statusBtnDone : statusBtnNotDone,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: Icon(
                      isDone
                          ? Atlas.check_circle_thin
                          : Icons.radio_button_off_outlined,
                      size: 48,
                    ),
                  ),
                  onTap: () async {
                    final updater = task.updateBuilder();
                    if (!isDone) {
                      updater.markDone();
                    } else {
                      updater.markUndone();
                    }
                    await updater.send();
                  },
                ),
                title: TaskTitle(
                  key: titleField,
                  task: task,
                ),
              ),
              ListTile(
                dense: true,
                leading: const Icon(Atlas.calendar_date_thin),
                title: Wrap(
                  children: [
                    DueChip(
                      visualDensity: VisualDensity.compact,
                      key: dueDateField,
                      canChange: true,
                      task: task,
                      noneChild: Text(
                        'No due date',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              fontWeight: FontWeight.w100,
                              fontStyle: FontStyle.italic,
                              color: AppTheme.brandColorScheme.neutral5,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              buildAssignees(context, ref),
              TaskBody(task: task),
            ],
          ),
        ),
      ],
    );
  }

  ListTile buildAssignees(BuildContext context, WidgetRef ref) {
    final assignees = task.assigneesStr().map((s) => s.toDartString()).toList();
    final account = ref.watch(accountProvider);
    final roomId = task.roomIdStr();

    return ListTile(
      key: assignmentsFields,
      dense: true,
      leading: const Icon(Atlas.business_man_thin),
      title: Wrap(
        children: [
          ...assignees
              .map(
                (userId) => UserChip(
                  visualDensity: VisualDensity.compact,
                  roomId: roomId,
                  memberId: userId,
                  deleteIcon:
                      const Icon(Atlas.xmark_circle_thin, key: selfUnassignKey),
                  onDeleted: account.hasValue &&
                          account.value!.userId().toString() == userId
                      ? () async {
                          await task.unassignSelf();
                          EasyLoading.showToast(
                            'assignment withdrawn',
                            toastPosition: EasyLoadingToastPosition.bottom,
                          );
                        }
                      : null,
                ),
              )
              .toList(),
          !task.isAssignedToMe()
              ? ActionChip(
                  key: selfAssignKey,
                  label: const Text('volunteer'),
                  onPressed: () async {
                    await task.assignSelf();
                    EasyLoading.showToast(
                      'assigned yourself',
                      toastPosition: EasyLoadingToastPosition.bottom,
                    );
                  },
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class TaskTitle extends StatefulWidget {
  final Task task;
  const TaskTitle({Key? key, required this.task}) : super(key: key);

  @override
  State<TaskTitle> createState() => _TaskTitleState();
}

class _TaskTitleState extends State<TaskTitle> {
  bool editMode = false;
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textController.text = widget.task.title();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    return editMode
        ? Form(
            key: _formKey,
            child: TextFormField(
              controller: _textController,
              autofocus: true,
              decoration: InputDecoration(
                suffixIcon: InkWell(
                  onTap: () => setState(() => editMode = false),
                  child: const Icon(Atlas.xmark_circle_thin),
                ),
              ),
              onFieldSubmitted: (value) async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  await _handleSubmit();
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'A task must have a title';
                }
                return null;
              },
            ),
          )
        : InkWell(
            onTap: () => setState(() => editMode = true),
            child: Text(
              task.title(),
              style: task.isDone()
                  ? Theme.of(context).textTheme.headlineMedium!.copyWith(
                        fontWeight: FontWeight.w100,
                        color: AppTheme.brandColorScheme.neutral5,
                      )
                  : Theme.of(context).textTheme.headlineSmall!,
            ),
          );
  }

  Future<void> _handleSubmit() async {
    final newString = _textController.text;
    if (newString != widget.task.title()) {
      try {
        EasyLoading.show(status: 'Updating task title');
        final updater = widget.task.updateBuilder();
        updater.title(newString);
        await updater.send();
        EasyLoading.showToast(
          'Title updated',
          toastPosition: EasyLoadingToastPosition.bottom,
        );
        setState(() => editMode = false);
      } catch (e) {
        EasyLoading.showError('Failed to update title: $e');
      }
    }
    setState(() => editMode = false);
  }
}

class TaskBody extends StatefulWidget {
  static const editKey = Key('task-body-edit');
  static const editorKey = Key('task-body-editor');
  static const saveEditKey = Key('task-body-save');
  static const cancelEditKey = Key('task-body-cancel');
  final Task task;
  const TaskBody({Key? key, required this.task}) : super(key: key);

  @override
  State<TaskBody> createState() => _TaskBodyState();
}

class _TaskBodyState extends State<TaskBody> {
  bool editMode = false;
  final TextEditingController _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final description = widget.task.description();
    if (description != null) {
      _textEditingController.text = description.body();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (editMode) {
      return Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            MdEditorWithPreview(
              key: TaskBody.editorKey,
              labelText: 'Notes',
              controller: _textEditingController,
            ),
            Wrap(
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton(
                  key: TaskBody.cancelEditKey,
                  onPressed: () => setState(() => editMode = false),
                  child: const Text('cancel'),
                ),
                OutlinedButton(
                  key: TaskBody.saveEditKey,
                  onPressed: () async {
                    final newBody = _textEditingController.text;
                    final description = widget.task.description();
                    if ((description == null &&
                            newBody.isEmpty) || // was nothing & stays nothing
                        (description != null &&
                            // was something and is the same;
                            description.body() == newBody)) {
                      // close and ignore, nothing actually changed
                      setState(() => editMode = false);
                    }

                    try {
                      EasyLoading.show(status: 'Updating task note');
                      final updater = widget.task.updateBuilder();
                      updater.descriptionText(newBody);
                      await updater.send();
                      EasyLoading.showToast(
                        'Notes updates',
                        toastPosition: EasyLoadingToastPosition.bottom,
                      );
                      setState(() => editMode = false);
                    } catch (e) {
                      EasyLoading.showError('Failed to update notes: $e');
                    }
                  },
                  child: const Text('save'),
                ),
              ],
            ),
          ],
        ),
      );
    }
    final description = widget.task.description();
    if (description != null) {
      final formattedBody = description.formattedBody();
      if (formattedBody != null && formattedBody.isNotEmpty) {
        return _contentWrap(context, RenderHtml(text: formattedBody));
      } else {
        final str = description.body();
        if (str.isNotEmpty) {
          return _contentWrap(
            context,
            Text(str),
          );
        }
      }
    }

    // fallback: none or empty string.
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Center(
        child: ActionChip(
          key: TaskBody.editKey,
          avatar: const Icon(Atlas.notebook_thin),
          label: const Text('add notes'),
          onPressed: () => setState(() => editMode = true),
        ),
      ),
    );
  }

  Widget _contentWrap(BuildContext context, Widget child) {
    return Stack(
      children: [
        Padding(
          padding:
              const EdgeInsets.only(left: 5, right: 5, bottom: 30, top: 10),
          child: child,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: IconButton(
            key: TaskBody.editKey,
            icon: const Icon(
              Atlas.pencil_edit_thin,
              size: 24,
            ),
            onPressed: () => setState(() => editMode = true),
          ),
        ),
      ],
    );
  }
}

class TaskInfoSkeleton extends StatelessWidget {
  const TaskInfoSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: Card(
        child: Column(
          children: [
            ListTile(
              leading: const Padding(
                padding: EdgeInsets.only(right: 5),
                child: Icon(
                  Icons.radio_button_off_outlined,
                  size: 48,
                ),
              ),
              title: Wrap(
                children: [
                  Text(
                    'Loading a task with a lengthy name so we have something nice to show',
                    style: Theme.of(context).textTheme.headlineMedium!,
                  ),
                ],
              ),
            ),
            const ListTile(
              dense: true,
              leading: Icon(Atlas.calendar_date_thin),
              title: Chip(
                label: Text('due date'),
              ),
            ),
            const ListTile(
              dense: true,
              leading: Icon(Atlas.business_man_thin),
              title: Text('no one is responsible yet'),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(
                'This is a multiline description of the task with lengthy texts and stuff',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
