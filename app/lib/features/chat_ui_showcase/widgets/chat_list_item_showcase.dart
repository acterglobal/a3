import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat_ui_showcase/models/mock_convo_data.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ChatListItemShowcase extends StatelessWidget {
  final MockConvo mockConvo;
  const ChatListItemShowcase({super.key, required this.mockConvo});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
      dense: true,
      leading: _buildLeading(context),
      title: _buildChatTitle(context),
      subtitle: _buildChatSubtitle(context),
    );
  }

  Widget _buildLeading(BuildContext context) {
    final isDM = mockConvo.isDM;
    return ActerAvatar(
      options:
          isDM
              ? AvatarOptions.DM(AvatarInfo(uniqueId: mockConvo.roomId))
              : AvatarOptions(AvatarInfo(uniqueId: mockConvo.roomId)),
    );
  }

  Widget _buildChatTitle(BuildContext context) {
    final timeColor =
        mockConvo.isUnread
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).textTheme.labelSmall?.color;

    return Row(
      children: [
        Text(
          mockConvo.displayName,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Spacer(),
        Text(
          jiffyTime(context, mockConvo.lastMessageTimestamp),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: timeColor),
        ),
      ],
    );
  }

  Widget _buildChatSubtitle(BuildContext context) {
    return Row(
      children: [
        mockConvo.isTyping
            ? _buildTypingIndicatorInfo(context)
            : _buildLastMessageInfo(context),
        Spacer(),
        if (mockConvo.isBookmarked)
          Icon(
            PhosphorIcons.bookmarkSimple(),
            size: 20,
            color: Theme.of(context).textTheme.labelMedium?.color,
          ),

        if (mockConvo.isMuted) ...[
          SizedBox(width: 6),
          Icon(
            PhosphorIcons.bellSlash(),
            size: 20,
            color: Theme.of(context).textTheme.labelMedium?.color,
          ),
        ],

        if (mockConvo.isUnread) ...[
          SizedBox(width: 6),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              mockConvo.unreadCount.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLastMessageInfo(BuildContext context) {
    final isDM = mockConvo.isDM;
    final lastMessage = mockConvo.lastMessage;
    final lastMessageSenderDisplayName = mockConvo.lastMessageSenderDisplayName;
    final textColor = Theme.of(context).textTheme.labelMedium?.color;

    final text =
        isDM ? lastMessage : '$lastMessageSenderDisplayName: $lastMessage';
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textColor),
    );
  }

  Widget _buildTypingIndicatorInfo(BuildContext context) {
    final secondaryColor = Theme.of(context).colorScheme.secondary;
    final isDM = mockConvo.isDM;
    final text =
        isDM
            ? 'Typing...'
            : '${mockConvo.lastMessageSenderDisplayName} is typing...';
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: secondaryColor),
    );
  }
}
