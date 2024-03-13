import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/html_editor.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/sliver_scaffold.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreatePinPage extends ConsumerStatefulWidget {
  final String? initialSelectedSpace;
  static const titleFieldKey = Key('create-pin-title-field');
  static const descriptionFieldKey = Key('create-pin-description-field');
  static const urlFieldKey = Key('create-pin-url-field');
  static const submitBtn = Key('create-pin-submit');

  const CreatePinPage({super.key, this.initialSelectedSpace});

  @override
  ConsumerState<CreatePinPage> createState() => _CreatePinSheetConsumerState();
}

class _CreatePinSheetConsumerState extends ConsumerState<CreatePinPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  EditorState textEditorState = EditorState.blank();
  AttachmentsManager? manager;
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
    return SliverScaffold(
      confirmActionKey: CreatePinPage.submitBtn,
      header: 'Create new Pin',
      addActions: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleField(),
                  const SizedBox(height: 15),
                  _buildLinkField(),
                  const SizedBox(height: 15),
                  _buildDescriptionField(),
                ],
              ),
              const SizedBox(height: 15),
              const SelectSpaceFormField(canCheck: 'CanPostPin'),
            ],
          ),
        ),
      ),
      confirmActionTitle: 'Create Pin',
      cancelActionTitle: null,
      confirmActionOnPressed: () async {
        if (_formKey.currentState!.validate()) {
          _handleCreatePin();
        }
      },
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 5),
          child: Text('Title'),
        ),
        InputTextField(
          hintText: 'Pin Name',
          key: CreatePinPage.titleFieldKey,
          textInputType: TextInputType.text,
          controller: _titleController,
          validator: (value) => (value != null && value.trim().isNotEmpty)
              ? null
              : 'Please enter a title',
        ),
      ],
    );
  }

  Widget _buildLinkField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(bottom: 5),
          child: Text('Link'),
        ),
        InputTextField(
          hintText: 'https://',
          key: CreatePinPage.urlFieldKey,
          textInputType: TextInputType.url,
          controller: _linkController,
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(bottom: 5),
          child: Text('Description'),
        ),
        Container(
          height: 200,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: HtmlEditor(
            key: CreatePinPage.descriptionFieldKey,
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

  void _handleCreatePin() async {
    EasyLoading.show(status: 'Creating pin...', dismissOnTap: false);
    try {
      final spaceId = ref.read(selectedSpaceIdProvider);
      final space = await ref.read(spaceProvider(spaceId!).future);
      final pinDraft = space.pinDraft();
      final title = _titleController.text;
      final url = _linkController.text;

      if (title.trim().isNotEmpty) {
        pinDraft.title(title);
      }

      final htmlText = textEditorState.intoHtml();
      final plainText = textEditorState.intoMarkdown();

      if (plainText.trim().isNotEmpty) {
        pinDraft.contentHtml(plainText, htmlText);
      } else {
        pinDraft.contentMarkdown(plainText);
      }

      if (url.isNotEmpty) {
        pinDraft.url(url);
      }
      final pinId = await pinDraft.send();

      // reset controllers
      _linkController.text = '';
      EasyLoading.showSuccess('Pin created successfully');
      // We are doing as expected, but the lints triggers.
      // ignore: use_build_context_synchronously
      if (!context.mounted) {
        return;
      }

      // ignore: use_build_context_synchronously
      Navigator.of(context, rootNavigator: true).pop(); // pop the create sheet
      // ignore: use_build_context_synchronously
      context.pushNamed(
        Routes.pin.name,
        pathParameters: {'pinId': pinId.toString()},
      );
    } catch (e) {
      // We are doing as expected, but the lints triggers.
      // ignore: use_build_context_synchronously
      if (!context.mounted) {
        return;
      }
      EasyLoading.showError('An error occured creating pin $e');
    }
  }
}
