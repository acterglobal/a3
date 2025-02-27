import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void showEditTitleBottomSheet({
  required BuildContext context,
  String? bottomSheetTitle,
  required String titleValue,
  required Function(WidgetRef, String) onSave,
}) {
  showModalBottomSheet(
    showDragHandle: true,
    useSafeArea: true,
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return EditTitleSheet(
        bottomSheetTitle: bottomSheetTitle,
        titleValue: titleValue,
        onSave: onSave,
      );
    },
  );
}

class EditTitleSheet extends ConsumerStatefulWidget {
  final String? bottomSheetTitle;
  final String titleValue;
  final Function(WidgetRef, String) onSave;

  const EditTitleSheet({
    super.key,
    this.bottomSheetTitle,
    required this.titleValue,
    required this.onSave,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _EditTitleSheetState();
}

class _EditTitleSheetState extends ConsumerState<EditTitleSheet> {
  final _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.titleValue;
  }

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return Container(
      padding: MediaQuery.of(context).viewInsets,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.bottomSheetTitle ?? lang.editTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 40),
          TextFormField(
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            controller: _titleController,
            autofocus: true,
            minLines: 1,
            maxLines: 1,
            decoration: InputDecoration(hintText: lang.name),
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
                  // no changes to submit
                  if (_titleController.text.trim() ==
                      widget.titleValue.trim()) {
                    Navigator.pop(context);
                    return;
                  }

                  // Need to update change of tile
                  widget.onSave(ref, _titleController.text.trim());
                },
                child: Text(lang.save),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
