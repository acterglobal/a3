import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/html_editor.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

const createPinPageKey = Key('create-pin-page');
const titleFieldKey = Key('create-pin-title-field');
const descriptionFieldKey = Key('create-pin-description-field');
const submitBtn = Key('create-pin-submit');

class CreatePin extends ConsumerStatefulWidget {
  final String? initialSelectedSpace;

  const CreatePin({
    super.key = createPinPageKey,
    this.initialSelectedSpace,
  });

  @override
  ConsumerState<CreatePin> createState() => _CreatePinConsumerState();
}

class _CreatePinConsumerState extends ConsumerState<CreatePin> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  EditorState textEditorState = EditorState.blank();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      if (widget.initialSelectedSpace != null &&
          widget.initialSelectedSpace!.isNotEmpty) {
        final parentNotifier = ref.read(selectedSpaceIdProvider.notifier);
        parentNotifier.state = widget.initialSelectedSpace;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(L10n.of(context).createPin),
    );
  }

  Widget _buildBody() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: 15),
            _buildTitleField(),
            const Align(
              alignment: Alignment.centerLeft,
              child: SelectSpaceFormField(
                canCheck: 'CanPostPin',
                isCompactView: true,
              ),
            ),
            const SizedBox(height: 15),
            _buildDescriptionField(),
            const SizedBox(height: 15),
            const SizedBox(height: 15),
            _buildCreateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(L10n.of(context).title),
        const SizedBox(height: 6),
        InputTextField(
          hintText: L10n.of(context).pinName,
          key: titleFieldKey,
          textInputType: TextInputType.text,
          controller: _titleController,
          validator: (value) => (value != null && value.trim().isNotEmpty)
              ? null
              : L10n.of(context).pleaseEnterATitle,
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(L10n.of(context).description),
        const SizedBox(height: 6),
        Container(
          height: 200,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: HtmlEditor(
            key: descriptionFieldKey,
            editable: true,
            autoFocus: false,
            editorState: textEditorState,
            footer: const SizedBox(),
            onChanged: (body, html) {
              final document = html != null
                  ? ActerDocumentHelpers.fromHtml(html)
                  : ActerDocumentHelpers.fromMarkdown(body);
              textEditorState = EditorState(document: document);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return ActerPrimaryActionButton(
      key: submitBtn,
      onPressed: () {},
      child: Text(L10n.of(context).create),
    );
  }
}
