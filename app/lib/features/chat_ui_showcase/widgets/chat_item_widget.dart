import 'package:acter/features/chat_ui_showcase/widgets/chat_item/chat_list_item_container_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatItemWidget extends ConsumerWidget {
  final String roomId;
  final Function()? onTap;
  const ChatItemWidget({super.key, required this.roomId, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ChatListItemContainerWidget(roomId: roomId, onTap: onTap);
  }
}
