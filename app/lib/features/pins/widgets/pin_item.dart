import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/html_editor.dart';
import 'package:acter/common/widgets/md_editor_with_preview.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/features/pins/pin_utils/pin_utils.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/pins/widgets/attachment_handler.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show ActerPin;
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
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
  String? htmlText;
  int? attachmentCount;

  @override
  void initState() {
    super.initState();
    _buildPinContent();
  }

  // pin content builder (default md-editor)
  void _buildPinContent() {
    final content = widget.pin.content();
    String? formattedBody;
    String markdown = 'No description';
    if (content != null) {
      if (content.formattedBody() != null) {
        formattedBody = content.formattedBody();
      } else {
        if (content.body().isNotEmpty) {
          markdown = content.body();
        }
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _buildAttachmentList(),
              ],
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
    final noAttachmentTextStyle = Theme.of(context)
        .textTheme
        .labelMedium!
        .copyWith(color: Theme.of(context).colorScheme.neutral5);
    final attachmentTitleTextStyle = Theme.of(context).textTheme.labelLarge;
    final pinEdit = ref.watch(pinEditProvider(widget.pin));
    final attachments = ref.watch(pinAttachmentsProvider(widget.pin));
    final selectedAttachments = ref.watch(selectedPinAttachmentsProvider);
    final attachmentNotifier =
        ref.watch(selectedPinAttachmentsProvider.notifier);
    return attachments.when(
      data: (list) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Text('Attachments', style: attachmentTitleTextStyle),
                  const SizedBox(width: 5),
                  const Icon(Atlas.paperclip_attachment_thin, size: 14),
                  const SizedBox(width: 5),
                  Text('${list.length}'),
                ],
              ),
            ),
            Wrap(
              spacing: 5.0,
              runSpacing: 10.0,
              children: <Widget>[
                if (list.isNotEmpty)
                  for (var item in list)
                    AttachmentTypeHandler(
                      attachment: item,
                      pin: widget.pin,
                    ),
                for (var item in selectedAttachments)
                  Stack(
                    children: <Widget>[
                      AttachmentContainer(
                        pin: widget.pin,
                        filename: item.file.path.split('/').last,
                        child: attachmentIconHandler(item.file, 20),
                      ),
                      Visibility(
                        visible: pinEdit.editMode,
                        child: Positioned(
                          top: -15,
                          right: -15,
                          child: IconButton(
                            onPressed: () {
                              var files =
                                  ref.read(selectedPinAttachmentsProvider);
                              files.remove(item);
                              attachmentNotifier.update((state) => [...files]);
                            },
                            icon: const Icon(Atlas.xmark_circle_thin, size: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (pinEdit.editMode) _buildAddAttachment(),
                Visibility(
                  visible: list.isEmpty && !pinEdit.editMode,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('No attachments', style: noAttachmentTextStyle),
                  ),
                ),
              ],
            ),
          ],
        );
      },
      error: (err, st) => Text('Error loading attachments $err'),
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
        replacement: RenderHtml(
          key: PinItem.descriptionFieldKey,
          text: descriptionController.text,
        ),
        child: Column(
          children: <Widget>[
            MdEditorWithPreview(
              key: PinItem.markdownEditorKey,
              controller: descriptionController,
            ),
            _ActionButtonsWidget(
              pin: pin,
              onSave: () async {
                if (formkey.currentState!.validate()) {
                  pinEditNotifier.setEditMode(false);
                  pinEditNotifier.setMarkdown(descriptionController.text);
                  pinEditNotifier.setLink(linkController.text);
                  await pinEditNotifier.onSave();
                }
              },
            ),
          ],
        ),
      );
    } else {
      final content = pin.content();
      return Visibility(
        visible: pinEdit.editMode,
        replacement: RenderHtml(
          key: PinItem.descriptionFieldKey,
          text: descriptionController.text,
        ),
        child: Column(
          children: <Widget>[
            Container(
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
                editable: true,
                editorState: content != null
                    ? EditorState(
                        document: ActerDocumentHelpers.fromMsgContent(content),
                      )
                    : null,
                onChanged: (body, html) {
                  if (html != null) {
                    descriptionController.text = html;
                  }
                  descriptionController.text = body;
                },
              ),
            ),
            _ActionButtonsWidget(
              pin: pin,
              onSave: () async {
                if (formkey.currentState!.validate()) {
                  pinEditNotifier.setEditMode(false);
                  pinEditNotifier.setHtml(descriptionController.text);
                  pinEditNotifier.setMarkdown(descriptionController.text);
                  pinEditNotifier.setLink(linkController.text);
                  await pinEditNotifier.onSave();
                }
              },
            ),
          ],
        ),
      );
    }
  }
}

// cancel submit buttons for create pin
class _ActionButtonsWidget extends ConsumerWidget {
  const _ActionButtonsWidget({
    required this.pin,
    required this.onSave,
  });
  final ActerPin pin;
  final void Function()? onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinEdit = ref.watch(pinEditProvider(pin));
    final pinEditNotifier = ref.watch(pinEditProvider(pin).notifier);
    return Visibility(
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
            onPressed: onSave,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
