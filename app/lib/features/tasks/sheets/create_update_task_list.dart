import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/acter_icon_picker/acter_icon_widget.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/common/toolkit/html_editor/html_editor.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/features/notifications/actions/autosubscribe.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::tasks::create_update_tasklist');

Future<void> showCreateUpdateTaskListBottomSheet(
  BuildContext context, {
  String? initialSelectedSpace,
}) async {
  await showModalBottomSheet(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (context) {
      return CreateUpdateTaskList(initialSelectedSpace: initialSelectedSpace);
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(
    debugLabel: 'create task list form',
  );
  final TextEditingController _titleController = TextEditingController();
  final ValueNotifier<bool> isShowDescription = ValueNotifier(false);
  EditorState textEditorState = EditorState.blank();
  ActerIcon? taskListIcon;
  Color? taskListIconColor;

  @override
  void initState() {
    super.initState();
    widget.initialSelectedSpace.map((p0) {
      WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
        ref.read(selectedSpaceIdProvider.notifier).state = p0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody(context);
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: MediaQuery.of(context).viewInsets,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  L10n.of(context).createNewTaskList,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 40),
                Center(
                  child: ActerIconWidget(
                    showEditIconIndicator: true,
                    onIconSelection: (taskListIconColor, taskListIcon) {
                      this.taskListIconColor = taskListIconColor;
                      this.taskListIcon = taskListIcon;
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _widgetTaskListName(),
                _widgetDescription(),
                const SizedBox(height: 20),
                SelectSpaceFormField(
                  canCheck: (m) => m?.canString('CanPostTaskList') == true,
                ),
                _widgetMoreDetails(),
                const SizedBox(height: 20),
                _widgetCreateButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _widgetTaskListName() {
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.taskListName, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 5),
        TextFormField(
          autofocus: true,
          key: CreateUpdateTaskList.titleKey,
          decoration: InputDecoration(hintText: lang.name),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          controller: _titleController,
          // required field, space not allowed
          validator:
              (val) =>
                  val == null || val.trim().isEmpty
                      ? lang.pleaseEnterAName
                      : null,
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
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white70),
                borderRadius: BorderRadius.circular(10),
              ),
              child: HtmlEditor(
                editorState: textEditorState,
                editable: true,
                onChanged: (body, html) {
                  textEditorState = EditorState(
                    document: ActerDocumentHelpers.parse(
                      body,
                      htmlContent: html,
                    ),
                  );
                },
              ),
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
    final lang = L10n.of(context);
    if (!_formKey.currentState!.validate()) return;
    EasyLoading.show(status: lang.postingTaskList);
    try {
      final spaceId = ref
          .read(selectedSpaceIdProvider)
          .expect('space not selected');
      final space = await ref.read(spaceProvider(spaceId).future);
      final taskListDraft = space.taskListDraft();

      // TaskList IconData

      if (taskListIconColor != null || taskListIcon != null) {
        final sdk = await ref.read(sdkProvider.future);
        final displayBuilder = sdk.api.newDisplayBuilder();
        taskListIconColor.map((color) => displayBuilder.color(color.toInt()));
        taskListIcon.map(
          (icon) => displayBuilder.icon('acter-icon', icon.name),
        );
        taskListDraft.display(displayBuilder.build());
      }

      taskListDraft.name(_titleController.text);
      // Description text
      final plainDescription = textEditorState.intoMarkdown();
      final htmlBodyDescription = textEditorState.intoHtml();
      taskListDraft.descriptionHtml(plainDescription, htmlBodyDescription);
      final objectId = await taskListDraft.send();
      await autosubscribe(ref: ref, objectId: objectId.toString(), lang: lang);

      EasyLoading.dismiss();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e, s) {
      _log.severe('Failed to create tasklist', e, s);
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.failedToCreateTaskList(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
