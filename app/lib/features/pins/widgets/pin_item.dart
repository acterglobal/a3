import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/html_editor.dart';
import 'package:acter/common/widgets/md_editor_with_preview.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/features/pins/pin_utils/pin_utils.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/pins/widgets/image_attachment_preview.dart';
import 'package:acter/features/pins/widgets/video_attachment_preview.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show ActerPin, Attachment;
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PinItem extends ConsumerStatefulWidget {
  static const linkFieldKey = Key('edit-pin-link-field');
  static const descriptionFieldKey = Key('edit-pin-description-field');
  static const markdownEditorKey = Key('edit-md-editor-field');
  static const richTextEditorKey = Key('edit-rich-editor-field');
  static const saveBtnKey = Key('pin-edit-save');
  final ActerPin pin;
  const PinItem(this.pin, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PinItemState();
}

class _PinItemState extends ConsumerState<PinItem> {
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();
  late TextEditingController _linkController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _buildPinContent();
  }

  // pin content builder (default md-editor)
  void _buildPinContent() {
    final content = widget.pin.content();
    String? formattedBody;
    String markdown = '';
    if (content != null) {
      if (content.formattedBody() != null) {
        formattedBody = content.formattedBody();
      } else {
        markdown = content.body();
      }
    }
    _linkController = TextEditingController(text: widget.pin.url() ?? '');
    _descriptionController = TextEditingController(
      text: formattedBody ?? markdown,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pin = widget.pin;
    final spaceId = pin.roomIdStr();
    final isLink = pin.isLink();
    final attachmentManager = ref.watch(pinAttachmentManagerProvider(pin));
    final attachmentTextStyle = Theme.of(context).textTheme.labelLarge;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Form(
        key: _formkey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              alignment: Alignment.topLeft,
              margin: const EdgeInsets.all(8),
              child: SpaceChip(spaceId: spaceId),
            ),
            if (isLink) _buildPinLink(),
            _PinDescriptionWidget(
              pin: pin,
              descriptionController: _descriptionController,
              linkController: _linkController,
              formkey: _formkey,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('Attachments', style: attachmentTextStyle),
            ),
            const SizedBox(height: 10),
            attachmentManager.when(
              data: (manager) {
                if (manager.hasAttachments()) {
                  return _buildAttachmentList();
                } else {
                  return _buildAddAttachment();
                }
              },
              loading: () => const Skeletonizer(child: SizedBox()),
              error: (err, st) => Text('failed to load attachments $err'),
            ),
          ],
        ),
      ),
    );
  }

  // pin link widget
  Widget _buildPinLink() {
    final pinEdit = ref.watch(pinEditProvider(widget.pin));
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        key: PinItem.linkFieldKey,
        onTap: () async =>
            !pinEdit.editMode ? await openLink(pinEdit.link, context) : null,
        controller: _linkController,
        readOnly: !pinEdit.editMode,
        decoration: const InputDecoration(
          prefixIcon: Icon(Atlas.link_chain_thin, size: 18),
        ),
        validator: (value) {
          if (value != null) {
            final uri = Uri.tryParse(value);
            if (uri == null || !uri.isAbsolute) {
              return 'link is not valid';
            }
          }
          return null;
        },
      ),
    );
  }

// attachment list UI
  Widget _buildAttachmentList() {
    final pinEdit = ref.watch(pinEditProvider(widget.pin));
    final attachments = ref.watch(pinAttachmentsProvider(widget.pin));
    final selectedAttachments = ref.watch(selectedAttachmentsProvider);
    return attachments.when(
      data: (list) {
        return Wrap(
          direction: Axis.horizontal,
          spacing: 5.0,
          runSpacing: 10.0,
          children: [
            for (var item in list) _AttachmentTypeHandler(item),
            for (var item in selectedAttachments)
              _AttachmentContainer(
                filename: item.file.path.split('/').last,
                child: const Icon(Atlas.file_thin),
              ),
            if (pinEdit.editMode) _buildAddAttachment(),
          ],
        );
      },
      error: (err, st) => Text('Failed to load attachments $err'),
      loading: () => const Skeletonizer(
        child: Wrap(
          spacing: 5.0,
          runSpacing: 10.0,
          children: [],
        ),
      ),
    );
  }

  // add attachment container UI
  Widget _buildAddAttachment() {
    final containerColor = Theme.of(context).colorScheme.background;
    final iconColor = Theme.of(context).colorScheme.secondary;
    final iconTextStyle = Theme.of(context).textTheme.labelLarge;

    return InkWell(
      onTap: () => PinUtils.showAttachmentSelection(context, ref),
      child: Container(
        height: 100,
        width: 100,
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.add, color: iconColor),
            Text('Add', style: iconTextStyle!.copyWith(color: iconColor)),
          ],
        ),
      ),
    );
  }
}

/// attachment file handler
class _AttachmentTypeHandler extends StatelessWidget {
  final Attachment attachment;
  const _AttachmentTypeHandler(this.attachment);
  @override
  Widget build(BuildContext context) {
    var msgContent = attachment.msgContent();
    String? mimeType = msgContent.mimetype();
    if (mimeType == null) {
      return ErrorWidget(Exception('Invalid Message Content'));
    }
    if (mimeType.startsWith('image/')) {
      return _AttachmentContainer(
        filename: msgContent.body(),
        child: ImageAttachmentPreview(attachment: attachment),
      );
    } else if (mimeType.startsWith('video/')) {
      return _AttachmentContainer(
        filename: msgContent.body(),
        child: VideoAttachmentPreview(attachment: attachment),
      );
    } else {
      return _AttachmentContainer(
        filename: msgContent.body(),
        child: const Center(child: Icon(Atlas.file_thin)),
      );
    }
  }
}

// outer attachment container UI
class _AttachmentContainer extends StatelessWidget {
  const _AttachmentContainer({
    required this.child,
    required this.filename,
  });
  final Widget child;
  final String filename;

  @override
  Widget build(BuildContext context) {
    final containerColor = Theme.of(context).colorScheme.background;
    final borderColor = Theme.of(context).colorScheme.primary;
    final containerTextStyle = Theme.of(context).textTheme.bodySmall;
    return Container(
      height: 100,
      width: 100,
      padding: const EdgeInsets.fromLTRB(3, 3, 3, 0),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(child: child),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
            child: Row(
              children: <Widget>[
                const Icon(Atlas.file_image_thin, size: 14),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    filename,
                    style: containerTextStyle!
                        .copyWith(overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// pin content UI widget
class _PinDescriptionWidget extends ConsumerWidget {
  const _PinDescriptionWidget({
    required this.pin,
    required this.descriptionController,
    required this.linkController,
    required this.formkey,
  });

  final ActerPin pin;
  final TextEditingController descriptionController;
  final TextEditingController linkController;
  final GlobalKey<FormState> formkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinEdit = ref.watch(pinEditProvider(pin));
    final pinEditNotifier = ref.watch(pinEditProvider(pin).notifier);
    final labFeature = ref.watch(featuresProvider);
    bool isActive(f) => labFeature.isActive(f);

    if (!isActive(LabsFeature.pinsEditor)) {
      return Visibility(
        visible: pinEdit.editMode,
        replacement: Html(
          key: PinItem.descriptionFieldKey,
          data: descriptionController.text,
          renderNewlines: true,
          padding: const EdgeInsets.all(8),
        ),
        child: Column(
          children: <Widget>[
            MdEditorWithPreview(
              key: PinItem.markdownEditorKey,
              controller: descriptionController,
            ),
            Visibility(
              visible: pinEdit.editMode,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  OutlinedButton(
                    onPressed: () => pinEditNotifier.setEditMode(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 5),
                  ElevatedButton(
                    key: PinItem.saveBtnKey,
                    onPressed: () async {
                      pinEditNotifier.setEditMode(false);
                      pinEditNotifier.setMarkdown(descriptionController.text);
                      pinEditNotifier.setLink(linkController.text);
                      await pinEditNotifier.onSave();
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      final content = pin.content();
      return Container(
        height: MediaQuery.of(context).size.height * 0.6,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: pinEdit.editMode
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          borderRadius: BorderRadius.circular(12),
        ),
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height),
        child: HtmlEditor(
          key: PinItem.richTextEditorKey,
          editable: pinEdit.editMode,
          editorState: content != null
              ? EditorState(
                  document: ActerDocumentHelpers.fromMsgContent(content),
                )
              : null,
          footer: pinEdit.editMode ? null : const SizedBox(),
          onCancel: () => pinEditNotifier.setEditMode(false),
          onSave: (plain, htmlBody) async {
            if (formkey.currentState!.validate()) {
              pinEditNotifier.setEditMode(false);
              pinEditNotifier.setLink(linkController.text);
              pinEditNotifier.setMarkdown(plain);
              if (htmlBody != null) {
                pinEditNotifier.setHtml(htmlBody);
              }
              await pinEditNotifier.onSave();
            }
          },
        ),
      );
    }
  }
}
