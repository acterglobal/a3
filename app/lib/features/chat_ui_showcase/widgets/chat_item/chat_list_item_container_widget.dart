import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/widgets/room_avatar.dart';
import 'package:acter/features/chat_ui_showcase/widgets/chat_item/last_message.dart';
import 'package:acter/features/chat_ui_showcase/widgets/chat_item/typing_indicator.dart';
import 'package:acter/features/chat_ui_showcase/widgets/chat_item/unread_count.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ChatListItemContainerWidget extends StatelessWidget {
  final String? roomId;
  final String displayName;
  final String lastMessage;
  final int? lastMessageTimestamp;
  final bool isDM;
  final String? lastMessageSenderDisplayName;
  final bool isUnread;
  final int? unreadCount;
  final List<String>? typingUsers;
  final bool isMuted;
  final bool isBookmarked;
  final Function()? onTap;

  const ChatListItemContainerWidget({
    super.key,
    this.roomId,
    required this.displayName,
    required this.lastMessage,
    required this.isDM,
    this.lastMessageTimestamp,
    this.lastMessageSenderDisplayName,
    this.isUnread = false,
    this.unreadCount = 0,
    this.typingUsers,
    this.isMuted = false,
    this.isBookmarked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading:
          roomId == null
              ? _buildChatAvatar(context)
              : RoomAvatar(roomId: roomId!, showParents: true),
      title: _buildChatTitle(context),
      subtitle: _buildChatSubtitle(context),
    );
  }

  Widget _buildChatAvatar(BuildContext context) {
    final avatarInfo = AvatarInfo(uniqueId: 'roomId');

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
        Expanded(
          child: Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(width: 12),

        //Show last message timestamp
        if (lastMessageTimestamp != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              jiffyTime(context, lastMessageTimestamp!),
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
        typingUsers != null && typingUsers!.isNotEmpty
            ? TypingIndicator(isDM: isDM, users: typingUsers!)
            : LastMessage(
              isUnread: isUnread,
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
