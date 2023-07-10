// import 'package:acter/features/chat/providers/notifiers/receipt_notifier.dart';
// import 'package:acter/features/chat/models/reciept_room/receipt_room.dart';
import 'package:acter/features/chat/providers/notifiers/chat_list_notifier.dart';
import 'package:acter/features/chat/models/chat_list_state/chat_list_state.dart';
import 'package:acter/features/chat/models/joined_room/joined_room.dart';
import 'package:acter/features/chat/providers/notifiers/joined_room_notifier.dart';
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

// CHAT Receipt Provider
// final receiptProvider =
//     StateNotifierProvider.autoDispose<ReceiptNotifier, ReceiptRoom?>(
//   (ref) => ReceiptNotifier(ref),
// );
