import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/widgets/md_editor_with_preview.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:acter/common/widgets/user_chip.dart';
import 'package:acter/features/attachments/widgets/attachment_section.dart';
import 'package:acter/features/comments/widgets/comments_section.dart';
import 'package:acter/features/tasks/widgets/due_chip.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::tasks::task_info');

class TaskInfo extends ConsumerWidget {
  static const statusBtnNotDone = Key('task-info-status-not-done');
  static const statusBtnDone = Key('task-info-status-done');
  static const titleField = Key('task-title');
  static const dueDateField = Key('task-due-field');
  static const assignmentsFields = Key('task-assignments');
  static const selfAssignKey = Key('task-self-assign');
  static const selfUnassignKey = Key('task-self-unassign');
  final Task task;

  const TaskInfo({super.key, required this.task});

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
                      size: 28,
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
                        L10n.of(context).noDueDate,
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              fontWeight: FontWeight.w100,
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context).colorScheme.neutral5,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              buildAssignees(context, ref),
              TaskBody(task: task),
              const SizedBox(height: 20),
              AttachmentSectionWidget(manager: task.attachments()),
              const SizedBox(height: 20),
              CommentsSection(manager: task.comments()),
              const SizedBox(height: 20),
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
          ...assignees.map(
            (userId) => UserChip(
              visualDensity: VisualDensity.compact,
              roomId: roomId,
              memberId: userId,
              deleteIcon: const Icon(
                Atlas.xmark_circle_thin,
                key: selfUnassignKey,
                size: 20,
              ),
              onDeleted: () => onUnassign(context, account, userId),
            ),
          ),
          !task.isAssignedToMe()
              ? ActionChip(
                  key: selfAssignKey,
                  label: Text(L10n.of(context).volunteer),
                  onPressed: () => onAssign(context),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Future<void> onUnassign(
    BuildContext context,
    Account account,
    String userId,
  ) async {
    if (account.userId().toString() == userId) return;
    EasyLoading.show(status: L10n.of(context).unassigningSelf);
    try {
      await task.unassignSelf();
      if (!context.mounted) return;
      EasyLoading.showToast(L10n.of(context).assignmentWithdrawn);
    } catch (e, st) {
      _log.severe('Failed to unassign self', e, st);
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

  Future<void> onAssign(BuildContext context) async {
    EasyLoading.show(status: L10n.of(context).assigningSelf);
    try {
      await task.assignSelf();
      if (!context.mounted) return;
      EasyLoading.showToast(L10n.of(context).assignedYourself);
    } catch (e, st) {
      _log.severe('Failed to assign self', e, st);
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
}

class TaskTitle extends StatefulWidget {
  final Task task;

  const TaskTitle({super.key, required this.task});

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
              onFieldSubmitted: _handleSubmit,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return L10n.of(context).aTaskMustHaveATitle;
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
                        color: Theme.of(context).colorScheme.neutral5,
                      )
                  : Theme.of(context).textTheme.headlineSmall!,
            ),
          );
  }

  Future<void> _handleSubmit(String value) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    final newString = _textController.text;
    if (newString == widget.task.title()) {
      setState(() => editMode = false);
      return;
    }
    EasyLoading.show(status: L10n.of(context).updatingTaskTitle);
    try {
      final updater = widget.task.updateBuilder();
      updater.title(newString);
      await updater.send();
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(L10n.of(context).titleUpdated);
      setState(() => editMode = false);
    } catch (e) {
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).failedToUpdateTitle(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}

class TaskBody extends StatefulWidget {
  static const editKey = Key('task-body-edit');
  static const editorKey = Key('task-body-editor');
  static const saveEditKey = Key('task-body-save');
  static const cancelEditKey = Key('task-body-cancel');

  final Task task;

  const TaskBody({super.key, required this.task});

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
              labelText: L10n.of(context).notes,
              controller: _textEditingController,
            ),
            Wrap(
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton(
                  key: TaskBody.cancelEditKey,
                  onPressed: () => setState(() => editMode = false),
                  child: Text(L10n.of(context).cancel),
                ),
                const SizedBox(
                  width: 10,
                ),
                OutlinedButton(
                  key: TaskBody.saveEditKey,
                  onPressed: onSave,
                  child: Text(L10n.of(context).save),
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
      if (formattedBody?.isNotEmpty == true) {
        return _contentWrap(context, RenderHtml(text: formattedBody!));
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
          label: Text(L10n.of(context).addNotes),
          onPressed: () => setState(() => editMode = true),
        ),
      ),
    );
  }

  Widget _contentWrap(BuildContext context, Widget child) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 5,
            right: 5,
            bottom: 30,
            top: 10,
          ),
          child: child,
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: IconButton(
            key: TaskBody.editKey,
            icon: const Icon(Atlas.pencil_edit_thin, size: 24),
            onPressed: () => setState(() => editMode = true),
          ),
        ),
      ],
    );
  }

  Future<void> onSave() async {
    final newBody = _textEditingController.text;
    final description = widget.task.description();

    final isNothing = description == null && newBody.isEmpty;
    final isSame = description?.body() == newBody;
    if (isNothing || isSame) {
      // close and ignore, nothing actually changed
      setState(() => editMode = false);
      return;
    }

    EasyLoading.show(status: L10n.of(context).updatingTaskNote);
    try {
      final updater = widget.task.updateBuilder();
      updater.descriptionText(newBody);
      await updater.send();
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(L10n.of(context).notesUpdates);
      setState(() => editMode = false);
    } catch (e) {
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).failedToLoadUpdateNotes(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}

class TaskInfoSkeleton extends StatelessWidget {
  const TaskInfoSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: Card(
        child: Column(
          children: [
            ListTile(
              leading: const Padding(
                padding: EdgeInsets.only(right: 5),
                child: Icon(Icons.radio_button_off_outlined, size: 48),
              ),
              title: Wrap(
                children: [
                  Text(
                    L10n.of(context).loadingATaskWithALengthyName,
                    style: Theme.of(context).textTheme.headlineMedium!,
                  ),
                ],
              ),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Atlas.calendar_date_thin),
              title: Chip(
                label: Text(L10n.of(context).dueDate),
              ),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Atlas.business_man_thin),
              title: Text(L10n.of(context).noOneIsResponsibleYet),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(L10n.of(context).thisIsAMultilineDescription),
            ),
          ],
        ),
      ),
    );
  }
}
