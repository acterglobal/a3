import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat_ui_showcase/widgets/chat_item/typing_indicator.dart';
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
        Text(
          displayName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Spacer(),
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
    final theme = Theme.of(context);
    return Row(
      children: [
        isTyping
            ? TypingIndicator(users: typingUsers ?? [])
            : _buildLastMessageInfo(context),
        Spacer(),
        if (isBookmarked)
          Icon(
            PhosphorIcons.bookmarkSimple(),
            size: 20,
            color: theme.textTheme.labelMedium?.color,
          ),

        if (isMuted) ...[
          SizedBox(width: 6),
          Icon(
            PhosphorIcons.bellSlash(),
            size: 20,
            color: theme.textTheme.labelMedium?.color,
          ),
        ],

        if (isUnread) ...[
          SizedBox(width: 6),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              unreadCount.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLastMessageInfo(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.surfaceTint;

    final text =
        isDM ? lastMessage : '$lastMessageSenderDisplayName: $lastMessage';
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(color: textColor),
    );
  }
}
