import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/tasks/providers/tasklists.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';

void showCreateUpdateTaskItemBottomSheet(
  BuildContext context, {
  required TaskList taskList,
  required String taskName,
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
        cancel: cancel,
      );
    },
  );
}

class CreateUpdateTaskItemList extends ConsumerStatefulWidget {
  final TaskList taskList;
  final String taskName;
  final Function()? cancel;

  const CreateUpdateTaskItemList({
    super.key,
    required this.taskList,
    required this.taskName,
    this.cancel,
  });

  @override
  ConsumerState<CreateUpdateTaskItemList> createState() =>
      _CreateUpdateItemListConsumerState();
}

class _CreateUpdateItemListConsumerState
    extends ConsumerState<CreateUpdateTaskItemList> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _taskNameController = TextEditingController();
  final TextEditingController _taskDescriptionController =
      TextEditingController();
  final TextEditingController _taskDueDateController = TextEditingController();
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    _taskNameController.text = widget.taskName;
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
                L10n.of(context).addTask,
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
          validator: (value) => (value?.isNotEmpty == true)
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
      ],
    );
  }

  Future<void> selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().addYears(1),
    );
    if (date == null || !mounted) return;
    selectedDate = date;
    _taskDueDateController.text = taskDueDateFormat(date);
    setState(() {});
  }

  Widget _widgetAddButton() {
    return ElevatedButton(
      onPressed: submitForm,
      child: Text(L10n.of(context).addTask),
    );
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    EasyLoading.show(status: L10n.of(context).addingTask);
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
      context.pop();
      ref.invalidate(spaceTasksListsProvider);
    } catch (e) {
      EasyLoading.dismiss();
      if (!mounted) return;
      EasyLoading.showError(
        L10n.of(context).creatingTaskFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
