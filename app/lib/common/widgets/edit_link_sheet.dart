import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

void showEditLinkBottomSheet({
  required BuildContext context,
  String? bottomSheetTitle,
  required String linkValue,
  required Function(String) onSave,
}) {
  showModalBottomSheet(
    showDragHandle: true,
    useSafeArea: true,
    context: context,
    constraints: const BoxConstraints(maxHeight: 300),
    builder: (context) {
      return EditLinkSheet(
        bottomSheetTitle: bottomSheetTitle,
        linkValue: linkValue,
        onSave: onSave,
      );
    },
  );
}

class EditLinkSheet extends ConsumerStatefulWidget {
  final String? bottomSheetTitle;
  final String linkValue;
  final Function(String) onSave;

  const EditLinkSheet({
    super.key,
    this.bottomSheetTitle,
    required this.linkValue,
    required this.onSave,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _EditTitleSheetState();
}

class _EditTitleSheetState extends ConsumerState<EditLinkSheet> {
  final _linkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _linkController.text = widget.linkValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      constraints: const BoxConstraints(maxWidth: 500),
      child: Column(
        children: [
          Text(
            widget.bottomSheetTitle ?? L10n.of(context).editLink,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 40),
          TextFormField(
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            controller: _linkController,
            autofocus: true,
            minLines: 1,
            maxLines: 1,
            decoration: InputDecoration(
              prefixIcon: const Icon(Atlas.link_chain_thin, size: 18),
              hintText: L10n.of(context).link,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => context.closeDialog(),
                child: Text(L10n.of(context).cancel),
              ),
              const SizedBox(width: 20),
              ActerPrimaryActionButton(
                onPressed: () {
                  // no changes to submit
                  if (_linkController.text.trim() == widget.linkValue.trim()) {
                    context.closeDialog();
                    return;
                  }

                  // Need to update change of tile
                  widget.onSave(_linkController.text.trim());
                },
                child: Text(L10n.of(context).save),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
