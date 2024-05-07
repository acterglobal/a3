import 'package:acter/common/providers/space_providers.dart';

import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/md_editor_with_preview.dart';
import 'package:acter/common/widgets/sliver_scaffold.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
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
    if (!_formKey.currentState!.validate()) return;
    EasyLoading.show(status: L10n.of(context).postingTaskList);
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

      EasyLoading.dismiss();
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      context.pushNamed(
        Routes.taskList.name,
        pathParameters: {'taskListId': taskListId.toString()},
      );
    } catch (e) {
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).failedToCreateTaskList(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textNotifier = ref.watch(textProvider.notifier);

    return SliverScaffold(
      header: L10n.of(context).createNewTaskList,
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
                        child: TextFormField(
                          key: CreateTaskListSheet.titleKey,
                          decoration: InputDecoration(
                            hintText: L10n.of(context).taskListName,
                            labelText: L10n.of(context).name,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          controller: _titleController,
                          validator: (value) => (value?.isNotEmpty == true)
                              ? null
                              : L10n.of(context).pleaseEnterAName,
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
        OutlinedButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.goNamed(Routes.main.name),
          child: Text(L10n.of(context).cancel),
        ),
        const SizedBox(width: 10),
        ActerPrimaryActionButton(
          key: CreateTaskListSheet.submitKey,
          onPressed: () async {
            await submitForm(context);
          },
          child: Text(L10n.of(context).createTaskList),
        ),
      ],
    );
  }
}
