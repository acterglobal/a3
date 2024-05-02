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

class EditRoomDescriptionSheet extends ConsumerWidget {
  final String description;
  final String roomId;

  EditRoomDescriptionSheet({
    super.key,
    required this.description,
    required this.roomId,
  });

  final _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _descriptionController.text = description;
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
    try {
      EasyLoading.show(status: L10n.of(context).updateDescription);
      context.pop();
      final convo = await ref.read(chatProvider(roomId).future);
      await convo.setTopic(_descriptionController.text.trim());
      EasyLoading.dismiss();
    } catch (e, st) {
      _log.severe('Failed to edit chat description', e, st);
      EasyLoading.dismiss();
    }
  }
}
