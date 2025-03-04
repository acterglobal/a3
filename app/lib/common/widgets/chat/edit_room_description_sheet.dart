import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::common::chat::room_description');

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
    final lang = L10n.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(lang.editDescription),
            const SizedBox(height: 20),
            TextFormField(
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              controller: _descriptionController,
              minLines: 4,
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
                  onPressed: () => _editDescription(context, ref),
                  child: Text(lang.save),
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
      Navigator.pop(context);
      return; // no changes to submit
    }
    final lang = L10n.of(context);

    try {
      EasyLoading.show(status: lang.updateDescription);
      final convo = await ref.read(chatProvider(widget.roomId).future);
      if (convo == null) {
        throw RoomNotFound();
      }
      await convo.setTopic(_descriptionController.text.trim());
      EasyLoading.dismiss();
      if (!context.mounted) return;
      Navigator.pop(context);
    } catch (e, s) {
      _log.severe('Failed to edit chat description', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.updateDescriptionFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
