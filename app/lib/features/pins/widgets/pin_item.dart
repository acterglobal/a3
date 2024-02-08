import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/html_editor.dart';
import 'package:acter/common/widgets/md_editor_with_preview.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show ActerPin;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PinItem extends ConsumerStatefulWidget {
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

  /// only for default markdown editor
  void _buildPinContent() {
    final content = widget.pin.content();
    String? formattedBody;
    String plainText = '';
    if (content != null) {
      if (content.formattedBody() != null) {
        formattedBody = content.formattedBody();
      } else {
        plainText = content.body();
      }
    }
    _linkController = TextEditingController(text: widget.pin.url() ?? '');
    _descriptionController =
        TextEditingController(text: formattedBody ?? plainText);
  }

  @override
  Widget build(BuildContext context) {
    final pin = widget.pin;
    final spaceId = pin.roomIdStr();
    final isLink = pin.isLink();
    final pinEdit = ref.watch(pinEditProvider(pin));
    final pinEditNotifier = ref.watch(pinEditProvider(pin).notifier);
    final labFeature = ref.watch(featuresProvider);
    bool isActive(f) => labFeature.isActive(f);
    final List<Widget> content = [
      Container(
        alignment: Alignment.topLeft,
        margin: const EdgeInsets.all(8),
        child: SpaceChip(spaceId: spaceId),
      ),
    ];

    if (isLink) {
      content.add(
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextFormField(
            onTap: () async => !pinEdit.editMode
                ? await openLink(pinEdit.link, context)
                : null,
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
        ),
      );
    }
    content.add(
      !isActive(LabsFeature.showPinRichEditor)
          ? Column(
              children: <Widget>[
                MdEditorWithPreview(
                  editable: pinEdit.editMode,
                  controller: _descriptionController,
                  onChanged: (value) => pinEditNotifier.setMarkdown(value),
                ),
                pinEdit.editMode
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          OutlinedButton(
                            onPressed: () => pinEditNotifier.setEditMode(false),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 5),
                          ElevatedButton(
                            onPressed: () async =>
                                await pinEditNotifier.onSave(),
                            child: const Text('Save'),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ],
            )
          : Container(
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
                editable: pinEdit.editMode,
                content: widget.pin.content(),
                footer: pinEdit.editMode ? null : const SizedBox(),
                onCancel: () => pinEditNotifier.setEditMode(false),
                onSave: (plain, htmlBody) async {
                  if (_formkey.currentState!.validate()) {
                    pinEditNotifier.setEditMode(false);
                    pinEditNotifier.setLink(_linkController.text);
                    pinEditNotifier.setPlainText(plain);
                    pinEditNotifier.setMarkdown(htmlBody);
                    await pinEditNotifier.onSave();
                  }
                },
              ),
            ),
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Form(
        key: _formkey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: content,
        ),
      ),
    );
  }
}
