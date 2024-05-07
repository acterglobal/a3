import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::chat::room_description_edit_sheet');

void showEditRoomDescriptionBottomSheet({
  required BuildContext context,
  required String description,
  required String roomId,
}) {
  showModalBottomSheet(
    showDragHandle: false,
    useSafeArea: true,
    context: context,
    isDismissible: false,
    constraints: const BoxConstraints(maxHeight: 500),
    builder: (context) {
      return EditRoomDescriptionSheet(description: description, roomId: roomId);
    },
  );
}

class EditRoomDescriptionSheet extends ConsumerStatefulWidget {
  final String description;
  final String roomId;

  const EditRoomDescriptionSheet({
    super.key,
    required this.description,
    required this.roomId,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _EditRoomDescriptionSheetState();
}

class _EditRoomDescriptionSheetState
    extends ConsumerState<EditRoomDescriptionSheet> {
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _descriptionController.text = widget.description;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(L10n.of(context).editDescription),
            const SizedBox(height: 20),
            TextFormField(
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              controller: _descriptionController,
              minLines: 4,
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
                  onPressed: () => context.pop(),
                  child: Text(L10n.of(context).cancel),
                ),
                const SizedBox(width: 20),
                ActerPrimaryActionButton(
                  onPressed: () => _editDescription(context, ref),
                  child: Text(L10n.of(context).save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editDescription(BuildContext context, WidgetRef ref) async {
    final newDesc = _descriptionController.text.trim();
    if (newDesc == widget.description.trim()) {
      context.pop();
      return; // no changes to submit
    }

    try {
      EasyLoading.show(status: L10n.of(context).updateDescription);
      final convo = await ref.read(chatProvider(widget.roomId).future);
      await convo.setTopic(_descriptionController.text.trim());
      EasyLoading.dismiss();
      if (!context.mounted) return;
      context.pop();
    } catch (e, st) {
      _log.severe('Failed to edit chat description', e, st);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(L10n.of(context).updateDescriptionFailed(e));
    }
  }
}
