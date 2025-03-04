import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show RoomEventItem;
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::chat::message_actions_redact');

Future<void> redactMessageAction(
  BuildContext context,
  RoomEventItem item,
  String messageId,
  String roomId,
) async {
  final lang = L10n.of(context);
  final senderId = item.sender();
  // pop message action options
  Navigator.pop(context);
  await showAdaptiveDialog(
    context: context,
    builder:
        (context) => Consumer(
          builder:
              (context, ref, child) => DefaultDialog(
                title: Text(lang.areYouSureYouWantToDeleteThisMessage),
                actions: <Widget>[
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(lang.no),
                  ),
                  ActerPrimaryActionButton(
                    onPressed: () async {
                      try {
                        final convo = await ref.read(
                          chatProvider(roomId).future,
                        );
                        await convo?.redactMessage(
                          messageId,
                          senderId,
                          null,
                          null,
                        );
                        ref
                            .read(chatEditorStateProvider.notifier)
                            .unsetActions();
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      } catch (e, s) {
                        _log.severe('Redacting message failed', e, s);
                        if (!context.mounted) return;
                        EasyLoading.showError(
                          lang.redactionFailed(e),
                          duration: const Duration(seconds: 3),
                        );
                        Navigator.pop(context);
                      }
                    },
                    child: Text(lang.yes),
                  ),
                ],
              ),
        ),
  );
}
