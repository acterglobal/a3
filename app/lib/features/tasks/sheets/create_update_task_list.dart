import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/widgets/md_editor_with_preview.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/features/tasks/providers/tasklists.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';

void showCreateUpdateTaskListBottomSheet(
  BuildContext context, {
  String? initialSelectedSpace,
}) {
  showModalBottomSheet(
    context: context,
    showDragHandle: false,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) {
      return CreateUpdateTaskList(
        initialSelectedSpace: initialSelectedSpace,
      );
    },
  );
}

class CreateUpdateTaskList extends ConsumerStatefulWidget {
  static const titleKey = Key('task-list-title');
  static const descKey = Key('task-list-desc');
  static const submitKey = Key('task-list-submit');
  final String? initialSelectedSpace;

  const CreateUpdateTaskList({super.key, this.initialSelectedSpace});

  @override
  ConsumerState<CreateUpdateTaskList> createState() =>
      _CreateUpdateTaskListConsumerState();
}

class _CreateUpdateTaskListConsumerState
    extends ConsumerState<CreateUpdateTaskList> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final ValueNotifier<bool> isShowDescription = ValueNotifier(false);
  final ValueNotifier<String> _descriptionText = ValueNotifier('');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      final spaceNotifier = ref.read(selectedSpaceIdProvider.notifier);
      spaceNotifier.state = widget.initialSelectedSpace;
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
              const Divider(indent: 150,endIndent: 150,thickness: 2,),
              const SizedBox(height: 20),
              Text(
                L10n.of(context).createNewTaskList,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              _widgetTaskListName(),
              _widgetDescription(),
              const SizedBox(height: 20),
              const SelectSpaceFormField(canCheck: 'CanPostTaskList'),
              _widgetMoreDetails(),
              const SizedBox(height: 20),
              _widgetCreateButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _widgetTaskListName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          L10n.of(context).taskListName,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 5),
        TextFormField(
          autofocus: true,
          key: CreateUpdateTaskList.titleKey,
          decoration: InputDecoration(
            hintText: L10n.of(context).name,
          ),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          controller: _titleController,
          validator: (value) => (value?.isNotEmpty == true)
              ? null
              : L10n.of(context).pleaseEnterAName,
        ),
      ],
    );
  }

  Widget _widgetDescription() {
    return ValueListenableBuilder(
      valueListenable: isShowDescription,
      builder: (context, isShowDescriptionValue, child) {
        if (!isShowDescriptionValue) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              L10n.of(context).description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            MdEditorWithPreview(
              key: CreateUpdateTaskList.descKey,
              onChanged: (String? value) {
                _descriptionText.value = value ?? '';
              },
            ),
          ],
        );
      },
    );
  }

  Widget _widgetMoreDetails() {
    return ValueListenableBuilder(
      valueListenable: isShowDescription,
      builder: (context, isShowDescriptionValue, child) {
        if (isShowDescriptionValue) return const SizedBox.shrink();
        return Align(
          alignment: Alignment.centerRight,
          child: ActerInlineTextButton(
            onPressed: () => isShowDescription.value = !isShowDescription.value,
            child: Text(L10n.of(context).addMoreDetails),
          ),
        );
      },
    );
  }

  Widget _widgetCreateButton() {
    return ElevatedButton(
      key: CreateUpdateTaskList.submitKey,
      onPressed: submitForm,
      child: Text(L10n.of(context).create),
    );
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    EasyLoading.show(status: L10n.of(context).postingTaskList);
    try {
      final spaceId = ref.read(selectedSpaceIdProvider);
      final space = await ref.read(spaceProvider(spaceId!).future);
      final taskListDraft = space.taskListDraft();
      taskListDraft.name(_titleController.text);
      if (_descriptionText.value.isNotEmpty) {
        taskListDraft.descriptionMarkdown(_descriptionText.value);
      }
      await taskListDraft.send();

      EasyLoading.dismiss();
      if (!mounted) return;
      context.pop();
      ref.invalidate(spaceTasksListsProvider);
    } catch (e) {
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).failedToCreateTaskList(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
