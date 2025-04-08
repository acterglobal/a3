import 'package:acter/features/chat/widgets/room_avatar.dart';
import 'package:acter/features/chat_ui_showcase/widgets/chat_item/display_name_widget.dart';
import 'package:acter/features/chat_ui_showcase/widgets/chat_item/last_message_time_widget.dart';
import 'package:acter/features/chat_ui_showcase/widgets/chat_item/last_message_widget.dart';
import 'package:acter/features/chat_ui_showcase/widgets/chat_item/bookmark_icon_widget.dart';
import 'package:acter/features/chat_ui_showcase/widgets/chat_item/mute_icon_widget.dart';
import 'package:acter/features/chat_ui_showcase/widgets/chat_item/typing_indicator.dart';
import 'package:acter/features/chat_ui_showcase/widgets/chat_item/unread_count_widget.dart';
import 'package:flutter/material.dart';

class ChatItemWidget extends StatelessWidget {
  final String roomId;
  final Function()? onTap;

  const ChatItemWidget({super.key, required this.roomId, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: RoomAvatar(roomId: roomId, showParents: true),
      title: _buildChatTitle(context),
      subtitle: _buildChatSubtitle(context),
    );
  }

  Widget _buildChatTitle(BuildContext context) {
    return Row(
      children: [
        //Show chat title
        Expanded(child: DisplayNameWidget(roomId: roomId)),
        SizedBox(width: 12),
        LastMessageTimeWidget(roomId: roomId),
      ],
    );
  }

  Widget _buildChatSubtitle(BuildContext context) {
    final isShowTyping = _isShowTyping();
    return Row(
      children: [
        Expanded(
          child:
              isShowTyping
                  ? TypingIndicator(roomId: roomId)
                  : LastMessageWidget(roomId: roomId),
        ),
        BookmarkIconWidget(roomId: roomId),
        MuteIconWidget(roomId: roomId),
        UnreadCountWidget(roomId: roomId),
      ],
    );
  }

  bool _isShowTyping() {
    return true;
  }
}
