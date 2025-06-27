import 'package:acter/features/chat_ng/actions/copy_message_action.dart';
import 'package:acter/features/chat_ng/actions/redact_message_action.dart';
import 'package:acter/features/chat_ng/actions/report_message_action.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show TimelineEventItem;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MessageActionsWidget extends ConsumerWidget {
  final bool isMe;
  final bool canRedact;
  final TimelineEventItem item;
  final String messageId;
  final String roomId;
  const MessageActionsWidget({
    super.key,
    required this.isMe,
    required this.canRedact,
    required this.item,
    required this.messageId,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final maxWidth =
        MediaQuery.of(context).size.width * 0.7; // 70% of screen width
    return IntrinsicWidth(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.all(8.0),
        margin: EdgeInsets.only(top: 4, left: 12, right: 12),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
        ),
        child: Column(
          children: menuItems(context, ref, lang).map((e) => e).toList(),
        ),
      ),
    );
  }

  List<Widget> menuItems(BuildContext context, WidgetRef ref, L10n lang) => [
    makeMenuItem(
      pressed: () async {
        ref.read(chatEditorStateProvider.notifier).setReplyToMessage(item);
        Navigator.pop(context);
      },
      text: Text(lang.reply),
      icon: const Icon(Icons.reply_rounded, size: 18),
    ),
    if (item.msgType() == 'm.text')
      makeMenuItem(
        pressed: () {
          final messageBody = item.msgContent()?.body();
          final messageHtml = item.msgContent()?.formattedBody();
          if (messageBody == null) return;
          copyMessageAction(context, messageBody, messageHtml);
        },
        text: Text(lang.copyMessage),
        icon: const Icon(Icons.copy_all_outlined, size: 14),
      ),
    if (isMe && item.msgType() == 'm.text')
      makeMenuItem(
        pressed: () {
          ref.read(chatEditorStateProvider.notifier).setEditMessage(item);
          Navigator.pop(context);
        },
        text: Text(lang.edit),
        icon: const Icon(Atlas.pencil_box_bold, size: 14),
      ),
    if (!isMe)
      makeMenuItem(
        pressed: () => reportMessageAction(context, item, messageId, roomId),
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
    if (canRedact)
      makeMenuItem(
        pressed: () => redactMessageAction(context, item, messageId, roomId),
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
  ];

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
          children: [text, if (icon != null) icon],
        ),
      ),
    );
  }
}
