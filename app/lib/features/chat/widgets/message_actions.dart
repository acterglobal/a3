import 'package:acter/common/actions/report_content.dart';
import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
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

  const MessageActions({
    super.key,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(
      chatInputProvider.select((state) => state.selectedMessage),
    );
    if (message == null) {
      // shouldn’t ever happen in reality
      return const SizedBox.shrink();
    }

    final lang = L10n.of(context);
    final myId = ref.watch(myUserIdStrProvider);
    final isAuthor = myId == message.author.id;
    final isTextMessage = message is TextMessage;

    return Container(
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(maxWidth: 200),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          makeMenuItem(
            pressed: () {
              ref.read(chatInputProvider.notifier).setReplyToMessage(message);
            },
            text: Text(lang.reply),
            icon: const Icon(
              Icons.reply_rounded,
              size: 18,
            ),
          ),
          if (isTextMessage)
            makeMenuItem(
              pressed: () => onCopyMessage(context, ref, message),
              text: Text(lang.copyMessage),
              icon: const Icon(
                Icons.copy_all_outlined,
                size: 14,
              ),
            ),
          if (isAuthor)
            makeMenuItem(
              pressed: () => onPressEditMessage(ref, message),
              text: Text(lang.edit),
              icon: const Icon(
                Atlas.pencil_box_bold,
                size: 14,
              ),
            ),
          if (!isAuthor)
            makeMenuItem(
              pressed: () => onReportMessage(context, message, roomId),
              text: Text(
                lang.report,
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
                message.remoteId ?? message.id,
                roomId,
              ),
              text: Text(
                lang.delete,
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
        padding: const EdgeInsets.symmetric(
          horizontal: 3,
          vertical: 5,
        ),
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

  Future<void> onCopyMessage(
    BuildContext context,
    WidgetRef ref,
    Message message,
  ) async {
    String msg = (message as TextMessage).text.trim();
    await Clipboard.setData(
      ClipboardData(text: msg),
    );
    if (context.mounted) {
      EasyLoading.showToast(L10n.of(context).messageCopiedToClipboard);
    }
    ref.read(chatInputProvider.notifier).unsetActions();
  }

  Future<void> onReportMessage(
    BuildContext context,
    Message message,
    String roomId,
  ) async {
    final lang = L10n.of(context);
    await openReportContentDialog(
      context,
      title: lang.reportThisMessage,
      description: lang.reportMessageContent,
      senderId: message.author.id,
      roomId: roomId,
      eventId: message.remoteId ?? message.id,
    );
  }

  Future<void> onDeleteOwnMessage(
    BuildContext context,
    WidgetRef ref,
    String messageId,
    String roomId,
  ) async {
    final chatInputNotifier = ref.watch(chatInputProvider.notifier);
    final lang = L10n.of(context);
    await showAdaptiveDialog(
      context: context,
      builder: (context) => DefaultDialog(
        title: Text(lang.areYouSureYouWantToDeleteThisMessage),
        actions: <Widget>[
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.no),
          ),
          ActerPrimaryActionButton(
            onPressed: () async {
              try {
                final convo = await ref.read(chatProvider(roomId).future);
                if (convo == null) throw RoomNotFound();
                await convo.redactMessage(
                  messageId,
                  ref.read(myUserIdStrProvider),
                  null,
                  null,
                );
                chatInputNotifier.unsetSelectedMessage();
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
    );
  }

  void onPressEditMessage(WidgetRef ref, Message message) {
    ref.read(chatInputProvider.notifier).setEditMessage(message);
  }
}
