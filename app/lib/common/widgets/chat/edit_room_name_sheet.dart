import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::chat::room_name_edit_sheet');

void showEditRoomNameBottomSheet({
  required BuildContext context,
  required String name,
  required String roomId,
}) {
  showModalBottomSheet(
    showDragHandle: false,
    useSafeArea: true,
    context: context,
    isDismissible: false,
    constraints: const BoxConstraints(maxHeight: 300),
    builder: (context) {
      return EditRoomNameSheet(name: name, roomId: roomId);
    },
  );
}

class EditRoomNameSheet extends ConsumerStatefulWidget {
  final String name;
  final String roomId;

  const EditRoomNameSheet({
    super.key,
    required this.name,
    required this.roomId,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _EditRoomNameSheetState();
}

class _EditRoomNameSheetState extends ConsumerState<EditRoomNameSheet> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.name;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(L10n.of(context).editName),
          const SizedBox(height: 20),
          TextFormField(
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            controller: _nameController,
            minLines: 1,
            maxLines: 1,
            decoration: InputDecoration(
              hintText: L10n.of(context).name,
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
                onPressed: () => _editName(context, ref),
                child: Text(L10n.of(context).save),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final newName = _nameController.text.trim();
    if (newName == widget.name.trim()) {
      context.pop();
      return; // no changes to submit
    }

    try {
      EasyLoading.show(status: L10n.of(context).updateName);
      final convo = await ref.read(chatProvider(widget.roomId).future);
      await convo.setName(_nameController.text.trim());
      EasyLoading.dismiss();
      if (!context.mounted) return;
      context.pop();
    } catch (e, st) {
      _log.severe('Failed to edit chat name', e, st);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(L10n.of(context).updateNameFailed(e));
    }
  }
}
