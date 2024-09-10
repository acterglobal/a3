import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/tasks/widgets/due_picker.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:dart_date/dart_date.dart';
import 'package:extension_nullable/extension_nullable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::tasks::create_update_task_item');

void showCreateUpdateTaskItemBottomSheet(
  BuildContext context, {
  required TaskList taskList,
  required String taskName,
  Task? task,
  Function()? cancel,
}) {
  showModalBottomSheet(
    context: context,
    showDragHandle: false,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) {
      return CreateUpdateTaskItemList(
        taskList: taskList,
        taskName: taskName,
        task: task,
        cancel: cancel,
      );
    },
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
    final task = widget.task;
    if (task == null) return;
    task.description().map((p0) => _taskDescriptionController.text = p0.body());
    task.dueDate().map((p0) {
      selectedDate = DateTime.parse(p0);
      selectedDate
          .map((p1) => _taskDueDateController.text = taskDueDateFormat(p1));
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody(context);
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                widget.task == null
                    ? L10n.of(context).addTask
                    : L10n.of(context).updateTask,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          L10n.of(context).taskName,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 5),
        TextFormField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: L10n.of(context).name,
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          controller: _taskNameController,
          validator: (val) => (val?.isNotEmpty == true)
              ? null
              : L10n.of(context).pleaseEnterAName,
        ),
      ],
    );
  }

  Widget _widgetDescriptionName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          L10n.of(context).description,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 5),
        TextFormField(
          decoration: InputDecoration(
            hintText: L10n.of(context).description,
          ),
          minLines: 4,
          maxLines: 4,
          controller: _taskDescriptionController,
        ),
      ],
    );
  }

  Widget _widgetDueDate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          L10n.of(context).dueDate,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 5),
        TextFormField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: L10n.of(context).dueDate,
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
              child: Text(L10n.of(context).today),
            ),
            ActerInlineTextButton(
              onPressed: () => setState(() {
                selectedDate = DateTime.now().addDays(1);
                _taskDueDateController.text = taskDueDateFormat(selectedDate!);
              }),
              child: Text(L10n.of(context).tomorrow),
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
    return ElevatedButton(
      onPressed: widget.task == null ? addTask : updateTask,
      child: Text(
        widget.task == null
            ? L10n.of(context).addTask
            : L10n.of(context).updateTask,
      ),
    );
  }

  Future<void> addTask() async {
    if (!_formKey.currentState!.validate()) return;
    EasyLoading.show(status: L10n.of(context).addingTask);
    final taskDraft = widget.taskList.taskBuilder();
    taskDraft.title(_taskNameController.text);
    if (_taskDescriptionController.text.isNotEmpty) {
      taskDraft.descriptionText(_taskDescriptionController.text);
    }
    selectedDate.map((p0) => taskDraft.dueDate(p0.year, p0.month, p0.day));
    try {
      await taskDraft.send();
      EasyLoading.dismiss();
      if (!mounted) return;
      widget.cancel.map((cb) => cb());
      Navigator.pop(context);
    } catch (e, s) {
      _log.severe('Failed to create task', e, s);
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).creatingTaskFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> updateTask() async {
    if (!_formKey.currentState!.validate()) return;
    final task = widget.task;
    if (task == null) return;
    EasyLoading.show(status: L10n.of(context).updatingTask);
    final updater = task.updateBuilder();
    updater.title(_taskNameController.text);
    if (_taskDescriptionController.text.isNotEmpty) {
      updater.descriptionText(_taskDescriptionController.text);
    }
    selectedDate.map((p0) => updater.dueDate(p0.year, p0.month, p0.day));
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
        L10n.of(context).updatingTaskFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
