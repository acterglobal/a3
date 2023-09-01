import 'package:acter/features/chat/models/receipt_room/receipt_room.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoomReceiptsNotifier extends StateNotifier<ReceiptRoom> {
  final Convo room;
  final Ref ref;
  RoomReceiptsNotifier({required this.room, required this.ref})
      : super(ReceiptRoom(roomId: room.getRoomIdStr(), receipts: {})) {
    init();
  }

  void init() async {
    final client = ref.read(clientProvider)!;
    var userReceipts =
        await room.userReceipts().then((ffiList) => ffiList.toList());
    Map<String, List<String>> receipts = {};
    List<String> userIds = [];
    for (ReceiptRecord record in userReceipts) {
      var eventId = record.eventId();
      if (record.seenBy() != client.userId().toString()) {
        userIds.add(record.seenBy());
      }
      receipts[eventId] = userIds;
    }
    state = state.copyWith(receipts: receipts);
  }
}

// class RecieptsNotifier extends StateNotifier {
//   final ReceiptEvent event;
//   final Ref ref;
//   RecieptsNotifier({required this.event, required this.ref}) : super(null);

//   void init() {
//     final client = ref.read(clientProvider);
//     String roomId = event.roomId().toString();
//     final currentRoom = ref.watch(currentConvoProvider);
//     if (currentRoom != null) {
//       if (currentRoom.getRoomIdStr() == roomId) {
//         final messages = ref.read(messagesProvider);
//         if (messages.isNotEmpty) {
//           for (ReceiptRecord record in event.receiptRecords().toList()) {
//             String seenBy = record.seenBy();
//             if (seenBy != client!.userId().toString()) {
//               final idx = record.eventId()
//             }
//           }
//         }
//       }
//     }
//   }
// }
