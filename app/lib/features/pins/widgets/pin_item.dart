import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/html_editor.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
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
  final GlobalKey<FormFieldState> _formkey = GlobalKey<FormFieldState>();
  @override
  Widget build(BuildContext context) {
    final membership =
        ref.watch(roomMembershipProvider(widget.pin.roomIdStr()));
    final canEdit = membership.valueOrNull != null
        ? membership.requireValue!.canString('CanPostPin')
            ? true
            : false
        : false;
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
                readOnly: !canEdit,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            onPressed: () async => await openLink(widget.pin.url()!, context),
          ),
        ),
      );
    }
    content.add(
      Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          height: double.infinity,
          padding: const EdgeInsets.all(8),
          child: HtmlEditor(
            editable: canEdit,
            autoFocus: autoFocus,
            content: widget.pin.contentText(),
            footer: const SizedBox(),
            onCancel: () => {},
            onSave: (plain, htmlBody) => {},
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: content,
      ),
    );
  }
}
