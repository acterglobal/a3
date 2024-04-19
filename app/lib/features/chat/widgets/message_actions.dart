import 'package:acter/common/providers/common_providers.dart';

import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter/common/widgets/report_content.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::chat::message_actions');

class MessageActions extends ConsumerWidget {
  final String roomId;
  final Convo convo;

  const MessageActions({super.key, required this.convo, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(
      chatInputProvider(roomId).select((state) => state.selectedMessage),
    );
    if (message == null) {
      // shouldn't ever happen in reality
      return const SizedBox.shrink();
    }

    final myId = ref.watch(myUserIdStrProvider);
    final isAuthor = (myId == message.author.id);
    bool isTextMessage = false;
    if (message is TextMessage) {
      isTextMessage = true;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(maxWidth: 200),
      margin: !isAuthor
          ? const EdgeInsets.only(top: 4)
          : const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        color: Theme.of(context).colorScheme.background,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          makeMenuItem(
            pressed: () => ref
                .read(chatInputProvider(roomId).notifier)
                .setReplyToMessage(message),
            text: Text(L10n.of(context).reply),
            icon: const Icon(Icons.reply_rounded, size: 18),
          ),
          if (isTextMessage)
            makeMenuItem(
              pressed: () => onCopyMessage(context, ref, message),
              text: Text(L10n.of(context).copyMessage),
              icon: const Icon(Icons.copy_all_outlined, size: 14),
            ),
          if (isAuthor)
            makeMenuItem(
              pressed: () => onPressEditMessage(context, ref, roomId, message),
              text: Text(L10n.of(context).edit),
              icon: const Icon(Atlas.pencil_box_bold, size: 14),
            ),
          if (!isAuthor)
            makeMenuItem(
              pressed: () => onReportMessage(context, message, roomId),
              text: Text(
                L10n.of(context).report,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              icon: Icon(
                Icons.flag_outlined,
                size: 14,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          // FIXME: should be a check whether the user can redact.
          if (isAuthor)
            makeMenuItem(
              pressed: () => onDeleteOwnMessage(
                context,
                ref,
                message.id,
                roomId,
              ),
              text: Text(
                L10n.of(context).delete,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              icon: Icon(
                Atlas.trash_can_thin,
                size: 14,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
        ],
      ),
    );
  }

  Widget makeMenuItem({
    required Widget text,
    Icon? icon,
    required void Function() pressed,
  }) {
    return InkWell(
      onTap: pressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            text,
            if (icon != null) icon,
          ],
        ),
      ),
    );
  }

  void onCopyMessage(BuildContext context, WidgetRef ref, Message message) {
    String msg = (message as TextMessage).text.trim();
    Clipboard.setData(
      ClipboardData(text: msg),
    );
    EasyLoading.showToast(L10n.of(context).messageCopiedToClipboard);
    ref.read(chatInputProvider(roomId).notifier).unsetActions();
  }

  void onReportMessage(BuildContext context, Message message, String roomId) {
    showAdaptiveDialog(
      context: context,
      builder: (context) => ReportContentWidget(
        title: L10n.of(context).reportThisMessage,
        description: L10n.of(context).reportMessageContent,
        senderId: message.author.id,
        roomId: roomId,
        eventId: message.id,
      ),
    );
  }

  void onDeleteOwnMessage(
    BuildContext context,
    WidgetRef ref,
    String messageId,
    String roomId,
  ) {
    final chatInputNotifier = ref.watch(chatInputProvider(roomId).notifier);
    showAdaptiveDialog(
      context: context,
      builder: (context) => DefaultDialog(
        title: Text(L10n.of(context).areYouSureYouWantToDeleteThisMessage),
        actions: <Widget>[
          OutlinedButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text(L10n.of(context).no),
          ),
          ActerPrimaryActionButton(
            onPressed: () async {
              try {
                await convo.redactMessage(
                  messageId,
                  ref.read(myUserIdStrProvider),
                  null,
                  null,
                );
                chatInputNotifier.unsetSelectedMessage();
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pop();
                }
              } catch (error, stackTrace) {
                _log.severe('Redacting message failed', error, stackTrace);
                if (context.mounted) {
                  Navigator.of(context, rootNavigator: true).pop();
                }
                EasyLoading.showError(error.toString());
              }
            },
            child: Text(L10n.of(context).yes),
          ),
        ],
      ),
    );
  }

  void onPressEditMessage(
    BuildContext context,
    WidgetRef ref,
    String roomId,
    Message message,
  ) {
    ref.read(chatInputProvider(roomId).notifier).setEditMessage(message);
  }
}
