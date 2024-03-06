import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/html_editor.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/md_editor_with_preview.dart';
import 'package:acter/common/widgets/sliver_scaffold.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/pins/pin_utils/pin_utils.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CreatePinPage extends ConsumerStatefulWidget {
  final String? initialSelectedSpace;
  static const titleFieldKey = Key('create-pin-title-field');
  static const contentFieldKey = Key('create-pin-content-field');
  static const urlFieldKey = Key('create-pin-url-field');
  static const submitBtn = Key('create-pin-submit');

  const CreatePinPage({super.key, this.initialSelectedSpace});

  @override
  ConsumerState<CreatePinPage> createState() => _CreatePinSheetConsumerState();
}

class _CreatePinSheetConsumerState extends ConsumerState<CreatePinPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  EditorState textEditorState = EditorState.blank();

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
    final attachments = ref.watch(selectedPinAttachmentsProvider);

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
                  _buildAttachmentField(),
                  const SizedBox(height: 15),
                  if (attachments.isNotEmpty)
                    Wrap(
                      spacing: 5.0,
                      runSpacing: 10.0,
                      children: <Widget>[
                        for (var pinAttachment in attachments)
                          _AttachmentItemWidget(pinAttachment),
                      ],
                    ),
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

  Widget _buildAttachmentField() {
    return InkWell(
      onTap: () => PinUtils.showAttachmentSelection(context, ref),
      child: Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Atlas.file_arrow_up_thin,
              size: 14,
              color: Theme.of(context).colorScheme.neutral5,
            ),
            Text(
              'Upload Attachment',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge!
                  .copyWith(color: Theme.of(context).colorScheme.neutral5),
            ),
          ],
        ),
      ),
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
          validator: (value) =>
              hasLinkOrText() ? null : 'Text or URL must be given',
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    final labFeature = ref.watch(featuresProvider);
    bool isActive(f) => labFeature.isActive(f);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(bottom: 5),
          child: Text('Description'),
        ),
        Visibility(
          visible: isActive(LabsFeature.pinsEditor),
          replacement: SizedBox(
            height: 200,
            child: MdEditorWithPreview(
              key: CreatePinPage.contentFieldKey,
              validator: (value) =>
                  hasLinkOrText() ? null : 'Text or URL must be given',
              controller: _textController,
            ),
          ),
          child: Container(
            height: 200,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: HtmlEditor(
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
        ),
      ],
    );
  }

  bool hasLinkOrText() {
    final htmlText = textEditorState.intoHtml();
    final plainText = textEditorState.intoMarkdown();
    final hasEditorText = htmlText.isNotEmpty || plainText.isNotEmpty;
    return _linkController.text.trim().isNotEmpty ||
        _textController.text.trim().isNotEmpty ||
        hasEditorText == true;
  }

  void _handleCreatePin() async {
    EasyLoading.show(status: 'Creating pin...');
    try {
      final labFeature = ref.watch(featuresProvider);
      bool isActive(f) => labFeature.isActive(f);
      final client = ref.read(alwaysClientProvider);
      final spaceId = ref.read(selectedSpaceIdProvider);
      final space = await ref.read(spaceProvider(spaceId!).future);
      final pinDraft = space.pinDraft();
      final title = _titleController.text;
      final text = _textController.text;
      final url = _linkController.text;

      if (title.trim().isNotEmpty) {
        pinDraft.title(title);
      }

      if (isActive(LabsFeature.pinsEditor)) {
        final htmlText = textEditorState.intoHtml();
        final plainText = textEditorState.intoMarkdown();
        pinDraft.contentHtml(plainText, htmlText);
      } else {
        pinDraft.contentMarkdown(text);
      }

      if (url.isNotEmpty) {
        pinDraft.url(url);
      }
      final pinId = await pinDraft.send();
      // pin sent okay, lets send attachments too.
      EasyLoading.show(status: 'Sending attachments...');
      final pin = await ref.read(pinProvider(pinId.toString()).future);
      final manager = await pin.attachments();
      final selectedAttachments = ref.read(selectedPinAttachmentsProvider);
      final List<AttachmentDraft>? drafts = await PinUtils.makeAttachmentDrafts(
        client,
        manager,
        selectedAttachments,
      );
      if (drafts == null) {
        EasyLoading.showError('Error occured sending attachments');
        return;
      }
      for (var draft in drafts) {
        await draft.send();
      }
      // reset controllers
      _textController.text = '';
      _linkController.text = '';
      EasyLoading.showSuccess('Pin created successfully');
      // We are doing as expected, but the lints triggers.
      // ignore: use_build_context_synchronously
      if (!context.mounted) {
        return;
      }
      // reset the selected attachment UI
      ref.invalidate(selectedPinAttachmentsProvider);
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

// Attachment Item UI widget
class _AttachmentItemWidget extends ConsumerWidget {
  const _AttachmentItemWidget(this.attachment);

  final SelectedAttachment attachment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachmentNotifier =
        ref.watch(selectedPinAttachmentsProvider.notifier);
    final file = attachment.file;
    String fileName = file.path.split('/').last;

    return Container(
      height: 30,
      width: 100,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: <Widget>[
          attachmentIconHandler(file, null),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              fileName,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall!
                  .copyWith(overflow: TextOverflow.ellipsis),
            ),
          ),
          const SizedBox(width: 5),
          InkWell(
            onTap: () {
              var files = ref.read(selectedPinAttachmentsProvider);
              files.remove(attachment);
              attachmentNotifier.update((state) => [...files]);
            },
            child: const Icon(Icons.close, size: 12),
          ),
        ],
      ),
    );
  }
}
