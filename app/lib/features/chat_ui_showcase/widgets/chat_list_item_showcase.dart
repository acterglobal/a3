import 'package:acter/common/utils/routes.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatListItemShowcase extends StatelessWidget {
  final int index;
  const ChatListItemShowcase({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final showDM = index % 3 == 0;
    final showUnread = index == 0 || index == 1;

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
      dense: true,
      leading: ActerAvatar(
        options:
            showDM
                ? AvatarOptions.DM(AvatarInfo(uniqueId: 'chat-1'))
                : AvatarOptions(AvatarInfo(uniqueId: 'chat-1')),
      ),
      onTap: () => context.pushNamed(Routes.chatMessagesShowcase.name),
      title: _buildChatTitle(context, showUnread),
      subtitle: _buildChatSubtitle(context, showUnread),
    );
  }

  Widget _buildChatTitle(BuildContext context, bool showUnread) {
    final timeColor =
        showUnread
            ? Theme.of(context).colorScheme.secondary
            : Theme.of(context).textTheme.labelSmall?.color;
    final timeFontWeight = showUnread ? FontWeight.bold : FontWeight.normal;

    return Row(
      children: [
        Text(
          'Acter Tech',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Spacer(),
        Text(
          '12:00 PM',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: timeColor,
            fontWeight: timeFontWeight,
          ),
        ),
      ],
    );
  }

  Widget _buildChatSubtitle(BuildContext context, bool showUnread) {
    return Row(
      children: [
        Text(
          'Kumar: Hey, how are you?',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).textTheme.labelMedium?.color,
          ),
        ),
        Spacer(),
        if (showUnread)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '1',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
      ],
    );
  }
}
