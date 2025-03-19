import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';

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
    final lang = L10n.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            Text(lang.editDescription),
            const SizedBox(height: 20),
            TextFormField(
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              controller: _descriptionController,
              minLines: 4,
              autofocus: true,
              maxLines: 4,
              decoration: InputDecoration(hintText: lang.description),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(lang.cancel),
                ),
                const SizedBox(width: 20),
                ActerPrimaryActionButton(
                  onPressed: () {
                    final newDescription = _descriptionController.text.trim();
                    // No need to change
                    if (newDescription == widget.descriptionValue.trim()) {
                      Navigator.pop(context);
                      return;
                    }

                    // Need to update change of tile
                    widget.onSave(newDescription);
                  },
                  child: Text(lang.save),
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
