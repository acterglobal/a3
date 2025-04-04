import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat_ui_showcase/widgets/chat_item/last_message.dart';
import 'package:acter/features/chat_ui_showcase/widgets/chat_item/typing_indicator.dart';
import 'package:acter/features/chat_ui_showcase/widgets/chat_item/unread_count.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ChatListItem extends StatelessWidget {
  final String roomId;
  final bool isDM;
  final String displayName;
  final String lastMessage;
  final int lastMessageTimestamp;
  final String? lastMessageSenderDisplayName;
  final bool isUnread;
  final int unreadCount;
  final bool isTyping;
  final List<String>? typingUsers;
  final bool isMuted;
  final bool isBookmarked;

  const ChatListItem({
    super.key,
    required this.roomId,
    required this.isDM,
    required this.displayName,
    required this.lastMessage,
    required this.lastMessageTimestamp,
    this.lastMessageSenderDisplayName,
    this.isUnread = false,
    this.unreadCount = 0,
    this.isTyping = false,
    this.typingUsers,
    this.isMuted = false,
    this.isBookmarked = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: _buildChatAvatar(context),
      title: _buildChatTitle(context),
      subtitle: _buildChatSubtitle(context),
    );
  }

  Widget _buildChatAvatar(BuildContext context) {
    final avatarInfo = AvatarInfo(uniqueId: roomId);

    final avatarOptions =
        isDM ? AvatarOptions.DM(avatarInfo) : AvatarOptions(avatarInfo);

    return ActerAvatar(options: avatarOptions);
  }

  Widget _buildChatTitle(BuildContext context) {
    final theme = Theme.of(context);
    final timeColor =
        isUnread ? theme.colorScheme.secondary : theme.colorScheme.surfaceTint;

    return Row(
      children: [
        //Show chat title
        Text(
          displayName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Spacer(),

        //Show last message timestamp
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            jiffyTime(context, lastMessageTimestamp),
            style: theme.textTheme.bodySmall?.copyWith(
              color: timeColor,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatSubtitle(BuildContext context) {
    return Row(
      children: [
        //Show typing indicator if it is typing else show last message
        isTyping
            ? TypingIndicator(users: typingUsers ?? [])
            : LastMessage(
              message: lastMessage,
              senderName: isDM ? null : lastMessageSenderDisplayName,
            ),
        Spacer(),

        //Show bookmarked icon if it is bookmarked
        if (isBookmarked)
          _builIconContainer(
            _builInfoIconItem(context, PhosphorIcons.bookmarkSimple()),
          ),

        //Show muted icon if it is muted
        if (isMuted)
          _builIconContainer(
            _builInfoIconItem(context, PhosphorIcons.bellSlash()),
          ),

        //Show unread count if it is unread
        if (isUnread) _builIconContainer(UnreadCount(count: unreadCount)),
      ],
    );
  }

  Widget _builInfoIconItem(BuildContext context, IconData icon) {
    final theme = Theme.of(context);
    return Icon(icon, size: 20, color: theme.textTheme.labelMedium?.color);
  }

  Widget _builIconContainer(Widget child) {
    return Row(children: [SizedBox(width: 6), child]);
  }
}
