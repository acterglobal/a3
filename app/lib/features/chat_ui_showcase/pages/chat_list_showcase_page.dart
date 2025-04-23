import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/plus_icon_widget.dart';
import 'package:acter/common/toolkit/widgets/animated_chats_list_widget.dart';
import 'package:acter/features/chat_ng/rooms_list/widgets/chat_item_widget.dart';
import 'package:acter/features/chat_ui_showcase/models/convo_showcase_list.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatListShowcasePage extends StatelessWidget {
  const ChatListShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(lang.chat),
        actions: [PlusIconWidget(onPressed: () {})],
      ),
      body: ActerAnimatedListWidget(
        entries: mockChatList.map((e) => e.roomId).toList(),
        itemBuilder:
            ({required Animation<double> animation, required String roomId}) =>
                ChatItemWidget(
                  onTap:
                      () => context.pushNamed(
                        Routes.chatMessageShowcase.name,
                        pathParameters: {'roomId': roomId},
                      ),
                  animation: animation,
                  key: Key('chat-room-card-$roomId'),
                  roomId: roomId,
                ),
      ),
    );
  }
}
