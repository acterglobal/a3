import 'package:acter/common/widgets/html_editor.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show ActerPin;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _editModeProvider = StateProvider<bool>((ref) => false);

class PinItem extends ConsumerStatefulWidget {
  final ActerPin pin;
  const PinItem(this.pin, {super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PinItemState();
}

class _PinItemState extends ConsumerState<PinItem> {
  final GlobalKey<FormFieldState> _formkey = GlobalKey<FormFieldState>();
  @override
  Widget build(BuildContext context) {
    final editMode = ref.watch(_editModeProvider);
    final isLink = widget.pin.isLink();
    final spaceId = widget.pin.roomIdStr();
    final autoFocus = widget.pin.contentText() != null
        ? widget.pin.contentText()!.body().isEmpty
            ? true
            : false
        : false;

    final List<Widget> content = [
      Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: SpaceChip(spaceId: spaceId),
      ),
    ];

    if (isLink) {
      content.add(
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: OutlinedButton.icon(
            icon: const Icon(Atlas.link_chain_thin),
            label: Form(
              key: _formkey,
              child: TextFormField(
                initialValue: widget.pin.url() ?? '',
                readOnly: !editMode,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
            onPressed: () =>
                ref.read(_editModeProvider.notifier).update((state) => true),
          ),
        ),
      );
    } else {
      content.add(
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            height: double.infinity,
            padding: const EdgeInsets.all(8),
            child: HtmlEditor(
              autoFocus: autoFocus,
              content: widget.pin.contentText(),
              footer: const SizedBox(),
              onCancel: () => {},
              onSave: (plain, htmlBody) => {},
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: content,
      ),
    );
  }
}
