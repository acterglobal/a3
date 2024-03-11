import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/html_editor.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show ActerPin;
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PinItem extends ConsumerStatefulWidget {
  static const linkFieldKey = Key('edit-pin-link-field');
  static const descriptionFieldKey = Key('edit-pin-description-field');
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
}

// pin content UI widget
class _PinDescriptionWidget extends ConsumerStatefulWidget {
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
  ConsumerState<_PinDescriptionWidget> createState() =>
      _PinDescriptionWidgetConsumerState();
}

class _PinDescriptionWidgetConsumerState
    extends ConsumerState<_PinDescriptionWidget> {
  late EditorState textEditorState;

  @override
  void initState() {
    super.initState();
    final content = widget.pin.content();
    if (content != null) {
      textEditorState =
          EditorState(document: ActerDocumentHelpers.fromMsgContent(content));
    } else {
      textEditorState = EditorState.blank();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pinEdit = ref.watch(pinEditProvider(widget.pin));
    final pinEditNotifier = ref.watch(pinEditProvider(widget.pin).notifier);

    return Column(
      children: <Widget>[
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: pinEdit.editMode
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          child: HtmlEditor(
            key: PinItem.descriptionFieldKey,
            shrinkWrap: true,
            editable: pinEdit.editMode,
            editorState: textEditorState,
            onChanged: (body, html) {
              final document = html != null
                  ? ActerDocumentHelpers.fromHtml(html)
                  : ActerDocumentHelpers.fromMarkdown(body);
              textEditorState = EditorState(document: document);
            },
          ),
        ),
        _ActionButtonsWidget(
          pin: widget.pin,
          onSave: () async {
            if (widget.formkey.currentState!.validate()) {
              pinEditNotifier.setEditMode(false);
              final htmlText = textEditorState.intoHtml();
              final plainText = textEditorState.intoMarkdown();
              pinEditNotifier.setHtml(htmlText);
              pinEditNotifier.setMarkdown(plainText);
              pinEditNotifier.setLink(widget.linkController.text);
              await pinEditNotifier.onSave();
            }
          },
        ),
      ],
    );
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
