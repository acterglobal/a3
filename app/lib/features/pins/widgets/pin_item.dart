import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/html_editor.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show ActerPin;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PinItem extends ConsumerStatefulWidget {
  final ActerPin pin;
  final ScrollController? controller;
  const PinItem(this.pin, this.controller, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PinItemState();
}

class _PinItemState extends ConsumerState<PinItem> {
  late TextEditingController _linkController;
  final GlobalKey<FormState> _formkey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _linkController = TextEditingController(text: widget.pin.url() ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final pinEdit = ref.watch(pinEditStateProvider(widget.pin));
    final pinEditNotifier =
        ref.watch(pinEditStateProvider(widget.pin).notifier);
    final isLink = widget.pin.isLink();
    final spaceId = widget.pin.roomIdStr();

    final List<Widget> content = [
      Container(
        alignment: Alignment.topLeft,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: SpaceChip(spaceId: spaceId),
      ),
    ];

    if (isLink) {
      content.add(
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextFormField(
            controller: _linkController,
            readOnly: !pinEdit.editMode,
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              prefixIcon: IconButton(
                onPressed: () async => await openLink(pinEdit.link, context),
                icon: const Icon(Atlas.link_chain_thin),
                iconSize: 18,
              ),
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
          editable: pinEdit.editMode,
          content: widget.pin.contentText(),
          footer: pinEdit.editMode ? null : const SizedBox(),
          onCancel: () => pinEditNotifier.setEditMode(false),
          onSave: (plain, htmlBody) async {
            if (_formkey.currentState!.validate()) {
              pinEditNotifier.setEditMode(false);
              pinEditNotifier.setLink(_linkController.text);
              pinEditNotifier.setPlainText(plain);
              pinEditNotifier.setHtml(htmlBody);
              await pinEditNotifier.onSave(context);
            }
          },
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(15),
      child: Form(
        key: _formkey,
        child: Column(
          children: content,
        ),
      ),
    );
  }
}
