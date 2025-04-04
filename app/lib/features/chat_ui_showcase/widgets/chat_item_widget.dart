import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/chat_ui_showcase/widgets/chat_item/chat_list_item_container_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatItemWidget extends ConsumerWidget {
  final String roomId;
  final Function()? onTap;
  const ChatItemWidget({super.key, required this.roomId, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = _getDisplayName(ref);
    final lastMessageTimestamp = _getLastMessageTimestamp(ref);
    final lastMessage = 'Hello, how are you?';
    final isMuted = _getIsMuted(ref);
    final isBookmarked = _getIsBookmarked(ref);
    final isDM = _getIsDM(ref);

    return ChatListItemContainerWidget(
      roomId: roomId,
      displayName: displayName,
      lastMessage: lastMessage,
      lastMessageTimestamp: lastMessageTimestamp,
      isDM: isDM,
      isMuted: isMuted,
      isBookmarked: isBookmarked,
      onTap: onTap,
    );
  }

  bool _getIsDM(WidgetRef ref) {
    final isDM = ref.watch(isDirectChatProvider(roomId));
    return isDM.valueOrNull ?? false;
  }

  bool _getIsBookmarked(WidgetRef ref) {
    final bookmarked = ref.watch(isConvoBookmarked(roomId));
    return bookmarked.valueOrNull ?? false;
  }

  bool _getIsMuted(WidgetRef ref) {
    final isMutedProvider = ref.watch(roomIsMutedProvider(roomId));
    return isMutedProvider.valueOrNull ?? false;
  }

  String _getDisplayName(WidgetRef ref) {
    final displayNameProvider = ref.watch(roomDisplayNameProvider(roomId));
    return displayNameProvider.valueOrNull ?? roomId;
  }

  int? _getLastMessageTimestamp(WidgetRef ref) {
    final latestMessage = ref.watch(latestMessageProvider(roomId)).valueOrNull;
    final TimelineEventItem? eventItem = latestMessage?.eventItem();
    final lastMessageTimestamp = eventItem?.originServerTs();
    return lastMessageTimestamp;
  }
}
