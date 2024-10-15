import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/tasks/widgets/due_picker.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::tasks::create_update_task_item');

Future<void> showCreateUpdateTaskItemBottomSheet(
  BuildContext context, {
  required TaskList taskList,
  required String taskName,
  Task? task,
  Function()? cancel,
}) async {
  await showModalBottomSheet(
    context: context,
    showDragHandle: false,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) => CreateUpdateTaskItemList(
      taskList: taskList,
      taskName: taskName,
      task: task,
      cancel: cancel,
    ),
  );
}

class CreateUpdateTaskItemList extends ConsumerStatefulWidget {
  final TaskList taskList;
  final String taskName;
  final Task? task;
  final Function()? cancel;

  const CreateUpdateTaskItemList({
    super.key,
    required this.taskList,
    required this.taskName,
    this.task,
    this.cancel,
  });

  @override
  ConsumerState<CreateUpdateTaskItemList> createState() =>
      _CreateUpdateItemListConsumerState();
}

class _CreateUpdateItemListConsumerState
    extends ConsumerState<CreateUpdateTaskItemList> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(debugLabel: 'update task list form');
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _taskDescriptionController =
      TextEditingController();
  final TextEditingController _taskDueDateController = TextEditingController();
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    _taskNameController.text = widget.taskName;
    setUpdateData();
  }

  void setUpdateData() {
    if (widget.task == null) return;
    if (widget.task!.description() != null) {
      _taskDescriptionController.text = widget.task!.description()!.body();
    }
    if (widget.task!.dueDate() != null) {
      selectedDate = DateTime.parse(widget.task!.dueDate()!);
      if (selectedDate != null) {
        _taskDueDateController.text = taskDueDateFormat(selectedDate!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody(context);
  }

  Widget _buildBody(BuildContext context) {
    final lang = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Divider(
                indent: 150,
                endIndent: 150,
                thickness: 2,
              ),
              const SizedBox(height: 20),
              Text(
                widget.task == null ? lang.addTask : lang.updateTask,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              _widgetTaskName(),
              const SizedBox(height: 20),
              _widgetDescriptionName(),
              const SizedBox(height: 20),
              _widgetDueDate(),
              const SizedBox(height: 20),
              _widgetAddButton(),
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
        Text(
          lang.description,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 5),
        TextFormField(
          decoration: InputDecoration(hintText: lang.description),
          minLines: 4,
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
        Text(
          lang.dueDate,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 5),
        TextFormField(
          readOnly: true,
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
              onPressed: () => setState(() {
                selectedDate = DateTime.now();
                _taskDueDateController.text = taskDueDateFormat(selectedDate!);
              }),
              child: Text(lang.today),
            ),
            ActerInlineTextButton(
              onPressed: () => setState(() {
                selectedDate = DateTime.now().addDays(1);
                _taskDueDateController.text = taskDueDateFormat(selectedDate!);
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

  Widget _widgetAddButton() {
    final lang = L10n.of(context);
    return ElevatedButton(
      onPressed: widget.task == null ? addTask : updateTask,
      child: Text(widget.task == null ? lang.addTask : lang.updateTask),
    );
  }

  Future<void> addTask() async {
    final lang = L10n.of(context);
    if (!_formKey.currentState!.validate()) return;
    EasyLoading.show(status: lang.addingTask);
    final taskDraft = widget.taskList.taskBuilder();
    taskDraft.title(_taskNameController.text);
    if (_taskDescriptionController.text.isNotEmpty) {
      taskDraft.descriptionText(_taskDescriptionController.text);
    }
    if (selectedDate != null) {
      taskDraft.dueDate(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
      );
    }
    try {
      await taskDraft.send();
      EasyLoading.dismiss();
      if (!mounted) return;
      if (widget.cancel != null) widget.cancel!();
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

  Future<void> updateTask() async {
    final lang = L10n.of(context);
    if (!_formKey.currentState!.validate() || widget.task == null) return;
    EasyLoading.show(status: lang.updatingTask);
    final updater = widget.task!.updateBuilder();
    updater.title(_taskNameController.text);
    if (_taskDescriptionController.text.isNotEmpty) {
      updater.descriptionText(_taskDescriptionController.text);
    }
    if (selectedDate != null) {
      updater.dueDate(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
      );
    }
    try {
      await updater.send();
      EasyLoading.dismiss();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e, s) {
      _log.severe('Failed to change task', e, s);
      if (!mounted) {
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
