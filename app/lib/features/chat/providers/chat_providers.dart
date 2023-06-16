import 'package:acter/features/chat/providers/notifiers/chat_room_notifier.dart';
import 'package:acter/features/chat/models/chat_input_state/chat_input_state.dart';
import 'package:acter/features/chat/models/chat_room_state/chat_room_state.dart';
import 'package:acter/features/chat/providers/notifiers/chat_input_notifier.dart';
import 'package:acter/features/chat/providers/notifiers/receipt_notifier.dart';
import 'package:acter/features/chat/models/reciept_room/receipt_room.dart';
import 'package:acter/features/chat/providers/notifiers/chat_list_notifier.dart';
import 'package:acter/features/chat/models/chat_list_state/chat_list_state.dart';
import 'package:acter/features/chat/models/invitation_profile.dart';
import 'package:acter/features/chat/models/joined_room/joined_room.dart';
import 'package:acter/features/chat/providers/notifiers/invitation_list_notifier.dart';
import 'package:acter/features/chat/providers/notifiers/joined_room_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Conversation, DispName, Invitation, UserProfile;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// CHAT PAGE state provider
final chatListProvider =
    StateNotifierProvider.autoDispose<ChatListNotifier, ChatListState>(
  (ref) => ChatListNotifier(ref),
);

// Conversations List Provider (CHAT PAGE)
final joinedRoomListProvider =
    StateNotifierProvider.autoDispose<JoinedRoomNotifier, List<JoinedRoom>>(
  (ref) => JoinedRoomNotifier(),
);

// Invitations List Provider (CHAT PAGE)
final invitationListProvider =
    StateNotifierProvider.autoDispose<InvitationListNotifier, List<Invitation>>(
  (ref) => InvitationListNotifier(),
);

final invitationProfileProvider =
    FutureProvider.family<InvitationProfile, Invitation>(
        (ref, invitation) async {
  UserProfile profile = invitation.getSenderProfile();
  DispName dispName = await profile.getDisplayName();
  String? roomName = await invitation.roomName();
  String roomId = invitation.roomId().toString();
  final avatar = await profile.getAvatar();
  return InvitationProfile(dispName.text(), avatar, roomName, roomId);
});

// CHAT Receipt Provider
final receiptProvider =
    StateNotifierProvider.autoDispose<ReceiptNotifier, ReceiptRoom?>(
  (ref) => ReceiptNotifier(ref),
);

final chatInputProvider =
    StateNotifierProvider<ChatInputNotifier, ChatInputState>(
  (ref) => ChatInputNotifier(ref),
);

final currentRoomProvider =
    StateProvider.autoDispose<Conversation?>((ref) => null);

final chatRoomProvider =
    StateNotifierProvider.autoDispose<ChatRoomNotifier, ChatRoomState>(
  (ref) => ChatRoomNotifier(ref),
);
