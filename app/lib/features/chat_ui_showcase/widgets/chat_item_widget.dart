import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/room_avatar.dart';
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
  final bool showSelectedIndication;
  final Function()? onTap;
  final Animation<double>? animation;

  const ChatItemWidget({
    super.key,
    required this.roomId,
    this.showSelectedIndication = false,
    this.onTap,
    this.animation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inner = _buildChatItem(context, ref);

    return animation != null
        ? SizeTransition(sizeFactor: animation!, child: inner)
        : inner;
  }

  Widget _buildChatItem(BuildContext context, WidgetRef ref) {
    final isChatSelected =
        showSelectedIndication && roomId == ref.watch(selectedChatIdProvider);

    return ListTile(
      selected: isChatSelected,
      selectedTileColor: Theme.of(context).colorScheme.primary,
      key: Key('chat-item-widget-$roomId'),
      dense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
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
        Expanded(child: DisplayNameWidget(roomId: roomId)),
        SizedBox(width: 12),
        LastMessageTimeWidget(roomId: roomId),
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
                  ? TypingIndicator(roomId: roomId)
                  : LastMessageWidget(roomId: roomId),
        ),
        BookmarkIconWidget(roomId: roomId),
        MuteIconWidget(roomId: roomId),
        UnreadCountWidget(roomId: roomId),
      ],
    );
  }

  List<User> _getTypingUsers(WidgetRef ref) {
    final users = ref.watch(chatTypingEventProvider(roomId)).valueOrNull;
    return users ?? [];
  }
}
