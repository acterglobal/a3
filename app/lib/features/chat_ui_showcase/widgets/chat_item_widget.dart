import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat_ui_showcase/widgets/chat_item/chat_list_item_container_widget.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatItemWidget extends ConsumerWidget {
  final String roomId;
  final Function()? onTap;
  const ChatItemWidget({super.key, required this.roomId, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final displayName = _getDisplayName(ref);
    final lastMessageTimestamp = _getLastMessageTimestamp(ref);
    final lastMessage = _getLastMessage(lang, ref);
    final lastMessageSenderName = _getLastMessageSenderName(ref);
    final isMuted = _getIsMuted(ref);
    final isBookmarked = _getIsBookmarked(ref);
    final isDM = _getIsDM(ref);
    final typingUsers = _getTypingUsers(ref);
    final unreadCount = _getUnreadCount(ref);
    final isUnread = _isUnread(ref);

    return ChatListItemContainerWidget(
      roomId: roomId,
      displayName: displayName,
      lastMessage: lastMessage,
      lastMessageTimestamp: lastMessageTimestamp,
      lastMessageSenderDisplayName: lastMessageSenderName,
      isDM: isDM,
      isMuted: isMuted,
      isBookmarked: isBookmarked,
      typingUsers: typingUsers,
      unreadCount: unreadCount,
      isUnread: isUnread,
      onTap: onTap,
    );
  }

  bool _isUnread(WidgetRef ref) {
    if (!ref.watch(isActiveProvider(LabsFeature.chatUnread))) return false;
    return ref.watch(hasUnreadMessages(roomId)).valueOrNull ?? false;
  }

  int? _getUnreadCount(WidgetRef ref) {
    if (!ref.watch(isActiveProvider(LabsFeature.chatUnread))) return null;

    final unreadCount = ref.watch(unreadCountersProvider(roomId)).valueOrNull;
    if (unreadCount == null) return null;
    final (notifications, mentions, messages) = unreadCount;
    return notifications;
  }

  List<String> _getTypingUsers(WidgetRef ref) {
    final users = ref.watch(chatTypingEventProvider(roomId)).valueOrNull;
    return users?.map((user) => user.id).toList() ?? [];
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

  String _getLastMessageSenderName(WidgetRef ref) {
    final latestMessage = ref.watch(latestMessageProvider(roomId)).valueOrNull;
    final TimelineEventItem? eventItem = latestMessage?.eventItem();
    final sender = eventItem?.sender();
    return simplifyUserId(sender ?? '') ?? '';
  }

  String _getLastMessage(L10n lang, WidgetRef ref) {
    final latestMessage = ref.watch(latestMessageProvider(roomId)).valueOrNull;
    final TimelineEventItem? eventItem = latestMessage?.eventItem();

    switch (eventItem?.eventType()) {
      case 'm.call.answer':
      case 'm.call.candidates':
      case 'm.call.hangup':
      case 'm.call.invite':
      case 'm.room.aliases':
      case 'm.room.avatar':
      case 'm.room.canonical_alias':
      case 'm.room.create':
      case 'm.room.encryption':
      case 'm.room.guest.access':
      case 'm.room.history_visibility':
      case 'm.room.join.rules':
      case 'm.room.name':
      case 'm.room.pinned_events':
      case 'm.room.power_levels':
      case 'm.room.server_acl':
      case 'm.room.third_party_invite':
      case 'm.room.tombstone':
      case 'm.room.topic':
      case 'm.space.child':
      case 'm.reaction':
      case 'm.sticker':
      case 'm.room.member':
      case 'm.space.parent':
      case 'm.room.message':
        final msgContent = eventItem?.msgContent();
        return msgContent?.body() ?? '';
      case 'm.room.encrypted':
        return lang.failedToDecryptMessage;
      case 'm.room.redaction':
        return lang.thisMessageHasBeenDeleted;
      default:
        return '';
    }
  }
}
