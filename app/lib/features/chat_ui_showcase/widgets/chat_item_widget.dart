import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/room_avatar.dart';
import 'package:acter/features/chat_ui_showcase/models/mock_convo_data.dart';
import 'package:acter/features/chat_ui_showcase/widgets/chat_item/display_name_widget.dart';
import 'package:acter/features/chat_ui_showcase/widgets/chat_item/last_message_time_widget.dart';
import 'package:acter/features/chat_ui_showcase/widgets/chat_item/last_message_widget.dart';
import 'package:acter/features/chat_ui_showcase/widgets/chat_item/bookmark_icon_widget.dart';
import 'package:acter/features/chat_ui_showcase/widgets/chat_item/mute_icon_widget.dart';
import 'package:acter/features/chat_ui_showcase/widgets/chat_item/typing_indicator.dart';
import 'package:acter/features/chat_ui_showcase/widgets/chat_item/unread_count_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatItemWidget extends ConsumerWidget {
  final String roomId;
  final Function()? onTap;
  final MockChatItem? mockChatItem;

  const ChatItemWidget({
    super.key,
    required this.roomId,
    this.onTap,
    this.mockChatItem,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: RoomAvatar(roomId: roomId, showParents: true),
      title: _buildChatTitle(context),
      subtitle: _buildChatSubtitle(context, ref),
    );
  }

  Widget _buildChatTitle(BuildContext context) {
    return Row(
      children: [
        //Show chat title
        Expanded(
          child: DisplayNameWidget(
            roomId: roomId,
            mockDisplayName: mockChatItem?.displayName,
          ),
        ),
        SizedBox(width: 12),
        LastMessageTimeWidget(
          roomId: roomId,
          mockLastMessageTimestamp: mockChatItem?.lastMessage.originServerTs(),
        ),
      ],
    );
  }

  Widget _buildChatSubtitle(BuildContext context, WidgetRef ref) {
    final typingUsers = _getTypingUsers(ref);
    return Row(
      children: [
        Expanded(
          child:
              typingUsers.isNotEmpty
                  ? TypingIndicator(
                    roomId: roomId,
                    mockTypingUsers: typingUsers,
                    mockIsDM: mockChatItem?.isDM,
                  )
                  : LastMessageWidget(
                    roomId: roomId,
                    mockLastMessage: mockChatItem?.lastMessage,
                    mockIsUnread:
                        mockChatItem != null && mockChatItem!.unreadCount > 0,
                  ),
        ),
        BookmarkIconWidget(
          roomId: roomId,
          mockIsBookmarked: mockChatItem?.isBookmarked,
        ),
        MuteIconWidget(roomId: roomId, mockIsMuted: mockChatItem?.isMuted),
        UnreadCountWidget(
          roomId: roomId,
          mockUnreadCount: mockChatItem?.unreadCount,
        ),
      ],
    );
  }

  List<User> _getTypingUsers(WidgetRef ref) {
    if (mockChatItem != null) return mockChatItem!.typingUsers ?? [];

    final users = ref.watch(chatTypingEventProvider(roomId)).valueOrNull;
    return users ?? [];
  }
}
