import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

void showEditPlainDescriptionBottomSheet({
  required BuildContext context,
  required String descriptionValue,
  required Function(String) onSave,
}) {
  showModalBottomSheet(
    showDragHandle: true,
    useSafeArea: true,
    context: context,
    isDismissible: true,
    builder: (context) {
      return EditPlainDescriptionSheet(
        descriptionValue: descriptionValue,
        onSave: onSave,
      );
    },
  );
}

class EditPlainDescriptionSheet extends StatefulWidget {
  final String descriptionValue;
  final Function(String) onSave;

  const EditPlainDescriptionSheet({
    super.key,
    required this.descriptionValue,
    required this.onSave,
  });

  @override
  State<EditPlainDescriptionSheet> createState() =>
      _EditPlainDescriptionSheetState();
}

class _EditPlainDescriptionSheetState extends State<EditPlainDescriptionSheet> {
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _descriptionController.text = widget.descriptionValue;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            Text(L10n.of(context).editDescription),
            const SizedBox(height: 20),
            TextFormField(
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              controller: _descriptionController,
              minLines: 4,
              autofocus: true,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: L10n.of(context).description,
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
                    final newDescription = _descriptionController.text.trim();
                    // No need to change
                    if (newDescription == widget.descriptionValue.trim()) {
                      context.closeDialog();
                      return;
                    }

                    // Need to update change of tile
                    widget.onSave(newDescription);
                  },
                  child: Text(L10n.of(context).save),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
