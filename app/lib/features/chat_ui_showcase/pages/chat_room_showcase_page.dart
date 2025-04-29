import 'package:acter/features/chat_ng/widgets/chat_editor/chat_editor_view.dart';
import 'package:acter/features/chat_ng/widgets/chat_room/app_bar_widget.dart';
import 'package:acter/features/chat_ng/widgets/events/chat_event.dart';
import 'package:acter/features/chat_ui_showcase/models/mocks/showcase_data/chat_event_showcase_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatRoomShowcasePage extends ConsumerWidget {
  final String roomId;
  const ChatRoomShowcasePage({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: ChatRoomAppBarWidget(roomId: roomId),
      body: Column(
        children: [
          Expanded(child: _buildMessagesList(ref)),
          ChatEditorView(key: Key('chat-editor-$roomId'), roomId: roomId),
        ],
      ),
    );
  }

  Widget _buildMessagesList(WidgetRef ref) => AnimatedList(
    initialItemCount: mockChatEventList.length,
    reverse: true,
    itemBuilder:
        (_, index, animation) => ChatEvent(
          roomId: roomId,
          eventId:
              mockChatEventList[index].mockTimelineEventItem?.mockEventId ?? '',
        ),
  );
}
