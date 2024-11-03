import 'package:acter/common/actions/select_space.dart';
import 'package:acter/common/drag_handle_widget.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/features/tasks/actions/select_tasklist.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter/features/tasks/widgets/due_picker.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::tasks::create_update_task_item');

Future<void> showCreateTaskBottomSheet(
  BuildContext context, {
  TaskList? taskList,
  String? taskName,
}) async {
  await showModalBottomSheet(
    context: context,
    showDragHandle: false,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => CreateTaskWidget(
      taskList: taskList,
      taskName: taskName,
    ),
  );
}

class CreateTaskWidget extends ConsumerStatefulWidget {
  static const submitBtn = Key('create-task-submit');
  static const titleField = Key('create-task-title-field');
  static const addDueDateAction = Key('create-task-actions-add-due');
  static const addDescAction = Key('create-task-actions-add-desc');
  static const dueDateField = Key('create-task-due-field');
  static const dueDateTodayBtn = Key('create-task-due-today-btn');
  static const dueDateTomorrowBtn = Key('create-task-due-tomorrow-btn');
  static const descField = Key('create-task-desc-field');
  static const closeDescAction = Key('create-task-actions-close-desc');
  static const closeDueDateAction = Key('create-task-actions-close-due-date');
  final TaskList? taskList;
  final String? taskName;

  const CreateTaskWidget({
    super.key,
    this.taskList,
    this.taskName,
  });

  @override
  ConsumerState<CreateTaskWidget> createState() =>
      _CreateTaskWidgetConsumerState();
}

class _CreateTaskWidgetConsumerState extends ConsumerState<CreateTaskWidget> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(debugLabel: 'create task list form');
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _taskDescriptionController =
      TextEditingController();
  final TextEditingController _taskDueDateController = TextEditingController();
  DateTime? selectedDate;

  bool showDescriptionField = false;
  bool showDueDate = false;

  TaskList? taskList;

  @override
  void initState() {
    super.initState();
    widget.taskList.map((tl) {
      WidgetsBinding.instance.addPostFrameCallback((d) {
        setState(() {
          taskList = tl;
          ref.read(selectedSpaceIdProvider.notifier).state = tl.spaceIdStr();
        });
      });
    });
    widget.taskName.map((text) {
      _taskNameController.text = text;
    });
    ref.listenManual(selectedSpaceIdProvider, (prev, next) {
      // if the space changed and this isn't our list now, we
      // need to reset
      if (next != taskList?.spaceIdStr()) {
        setState(() {
          taskList = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);

    final fields = [
      const SizedBox(height: 20),
      _widgetTaskName(),
    ];

    if (showDescriptionField) {
      fields.addAll([
        const SizedBox(height: 20),
        _widgetDescriptionName(),
      ]);
    }

    if (showDueDate) {
      fields.addAll([
        const SizedBox(height: 20),
        _widgetDueDate(),
      ]);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              const Center(child: DragHandleWidget()),
              const SizedBox(height: 20),
              Text(
                lang.addTask,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                child: Row(
                  children: [
                    const SelectSpaceFormField(
                      canCheck: 'CanPostTask',
                      useCompactView: true,
                    ),
                    const Text(' > '),
                    if (taskList == null)
                      ActerInlineTextButton(
                        child: Text(lang.selectTaskList),
                        onPressed: () => _selectTaskList(),
                      )
                    else
                      InkWell(
                        onTap: () => _selectTaskList(),
                        child: Text(taskList?.name() ?? ''),
                      ),
                  ],
                ),
              ),
              ...fields,
              const SizedBox(height: 20),
              _addFields(),
              const SizedBox(height: 20),
              _widgetCreateButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _widgetTaskName() {
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.taskName,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 5),
        TextFormField(
          key: CreateTaskWidget.titleField,
          autofocus: true,
          decoration: InputDecoration(hintText: lang.name),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          controller: _taskNameController,
          // required field, space not allowed
          validator: (val) =>
              val == null || val.trim().isEmpty ? lang.pleaseEnterAName : null,
        ),
      ],
    );
  }

  Widget _widgetDescriptionName() {
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              lang.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            IconButton(
              key: CreateTaskWidget.closeDescAction,
              onPressed: () {
                setState(() {
                  showDescriptionField = false;
                });
              },
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 5),
        TextFormField(
          key: CreateTaskWidget.descField,
          decoration: InputDecoration(hintText: lang.description),
          minLines: 2,
          maxLines: 4,
          controller: _taskDescriptionController,
        ),
      ],
    );
  }

  Widget _widgetDueDate() {
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              lang.dueDate,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            IconButton(
              key: CreateTaskWidget.closeDueDateAction,
              onPressed: () {
                setState(() {
                  showDueDate = false;
                });
              },
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 5),
        TextFormField(
          readOnly: true,
          key: CreateTaskWidget.dueDateField,
          decoration: InputDecoration(
            hintText: lang.dueDate,
            suffixIcon: IconButton(
              onPressed: selectDueDate,
              icon: const Icon(Icons.calendar_month),
            ),
          ),
          onTap: selectDueDate,
          controller: _taskDueDateController,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ActerInlineTextButton(
              key: CreateTaskWidget.dueDateTodayBtn,
              onPressed: () => setState(() {
                final date = DateTime.now();
                selectedDate = date;
                _taskDueDateController.text = taskDueDateFormat(date);
              }),
              child: Text(lang.today),
            ),
            ActerInlineTextButton(
              key: CreateTaskWidget.dueDateTomorrowBtn,
              onPressed: () => setState(() {
                final date = DateTime.now().addDays(1);
                selectedDate = date;
                _taskDueDateController.text = taskDueDateFormat(date);
              }),
              child: Text(lang.tomorrow),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> selectDueDate() async {
    final due = await showDuePicker(
      context: context,
      initialDate: selectedDate,
    );
    if (due == null || !mounted) return;
    final date = due.due;
    setState(() {
      selectedDate = date;
      _taskDueDateController.text = taskDueDateFormat(date);
    });
  }

  Widget _addFields() {
    final lang = L10n.of(context);
    final actions = [];
    if (!showDescriptionField) {
      actions.add(
        ActerInlineTextButton(
          key: CreateTaskWidget.addDescAction,
          onPressed: () => setState(() {
            showDescriptionField = true;
          }),
          child: Text(lang.description),
        ),
      );
    }
    if (!showDueDate) {
      actions.add(
        ActerInlineTextButton(
          key: CreateTaskWidget.addDueDateAction,
          onPressed: () => setState(() {
            showDueDate = true;
          }),
          child: Text(lang.dueDate),
        ),
      );
    }
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Text(lang.add),
        const SizedBox(width: 5),
        ...actions,
      ],
    );
  }

  Widget _widgetCreateButton() {
    final lang = L10n.of(context);
    return ElevatedButton(
      key: CreateTaskWidget.submitBtn,
      onPressed: addTask,
      child: Text(lang.addTask),
    );
  }

  Future<void> _selectTaskList() async {
    final lang = L10n.of(context);
    String? spaceId = ref.read(selectedSpaceIdProvider);
    spaceId ??= await selectSpace(
      context: context,
      ref: ref,
      canCheck: 'CanPostTask',
    );
    if (!mounted) return;

    if (spaceId == null) {
      EasyLoading.showError(
        lang.pleaseSelectSpace,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    final taskListId = await selectTaskList(context: context, spaceId: spaceId);
    if (!mounted) return;
    if (taskListId == null) {
      return;
    }

    final newTaskList = await ref.read(taskListItemProvider(taskListId).future);
    setState(() {
      taskList = newTaskList;
    });
  }

  Future<void> addTask() async {
    final lang = L10n.of(context);
    if (!_formKey.currentState!.validate()) return;

    if (taskList == null) {
      await _selectTaskList();
    }
    final tl = taskList;
    if (tl == null) {
      EasyLoading.showError(
        lang.selectTaskList,
        duration: const Duration(seconds: 2),
      );
      return;
    }

    EasyLoading.show(status: lang.addingTask);
    final taskDraft = tl.taskBuilder();
    taskDraft.title(_taskNameController.text);
    if (showDescriptionField && _taskDescriptionController.text.isNotEmpty) {
      taskDraft.descriptionText(_taskDescriptionController.text);
    }
    final date = selectedDate;
    if (showDueDate && date != null) {
      taskDraft.dueDate(date.year, date.month, date.day);
    }
    try {
      await taskDraft.send();
      EasyLoading.dismiss();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e, s) {
      _log.severe('Failed to create task', e, s);
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.creatingTaskFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
