import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter/common/widgets/md_editor_with_preview.dart';
import 'package:acter/common/widgets/side_sheet.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// interface data providers
final textProvider = StateProvider<String>((ref) => '');

class CreateTaskListSheet extends ConsumerStatefulWidget {
  static const titleKey = Key('task-list-title');
  static const descKey = Key('task-list-desc');
  static const submitKey = Key('task-list-submit');
  final String? initialSelectedSpace;
  const CreateTaskListSheet({super.key, this.initialSelectedSpace});

  @override
  ConsumerState<CreateTaskListSheet> createState() =>
      _CreateTaskListSheetConsumerState();
}

class _CreateTaskListSheetConsumerState
    extends ConsumerState<CreateTaskListSheet> {
  final TextEditingController _titleController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      final spaceNotifier = ref.read(selectedSpaceIdProvider.notifier);
      spaceNotifier.state = widget.initialSelectedSpace;
    });
  }

  Future<void> submitForm(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      DefaultDialog(
        title: Text(
          'Posting TaskList',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        isLoader: true,
      );
      try {
        final spaceId = ref.read(selectedSpaceIdProvider);
        final space = await ref.read(spaceProvider(spaceId!).future);
        final taskListDraft = space.taskListDraft();
        final text = ref.read(textProvider);
        taskListDraft.name(_titleController.text);
        if (text.isNotEmpty) {
          taskListDraft.descriptionMarkdown(text);
        }
        final taskListId = await taskListDraft.send();
        // reset providers

        _titleController.text = '';
        ref.read(textProvider.notifier).state = '';

        // We are doing as expected, but the lints triggers.
        // ignore: use_build_context_synchronously
        if (!context.mounted) {
          return;
        }
        Navigator.of(context, rootNavigator: true).pop();
        context.pushNamed(
          Routes.taskList.name,
          pathParameters: {'taskListId': taskListId.toString()},
        );
      } catch (e) {
        // We are doing as expected, but the lints triggers.
        // ignore: use_build_context_synchronously
        if (!context.mounted) {
          return;
        }
        customMsgSnackbar(context, 'Failed to create task list: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textNotifier = ref.watch(textProvider.notifier);

    return SideSheet(
      header: 'Create new task list',
      addActions: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: TextFormField(
                          key: CreateTaskListSheet.titleKey,
                          decoration: InputDecoration(
                            hintText: 'Task list name',
                            labelText: 'Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          controller: _titleController,
                          validator: (value) =>
                              (value != null && value.isNotEmpty)
                                  ? null
                                  : 'Please enter a name',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              MdEditorWithPreview(
                key: CreateTaskListSheet.descKey,
                onChanged: (String? value) {
                  textNotifier.state = value ?? '';
                },
              ),
              const SelectSpaceFormField(canCheck: 'CanPostTaskList'),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.goNamed(Routes.main.name),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            foregroundColor: Theme.of(context).colorScheme.neutral6,
            textStyle: Theme.of(context).textTheme.bodySmall,
          ),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          key: CreateTaskListSheet.submitKey,
          onPressed: () async {
            await submitForm(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.success,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            textStyle: Theme.of(context).textTheme.bodySmall,
          ),
          child: const Text('Create task list'),
        ),
      ],
    );
  }
}
