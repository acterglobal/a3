import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show Conversation, RoomMessage;
import 'package:get/get.dart';

//Helper class.
class RoomItem {
  Conversation conversation;
  LatestMessage? latestMessage;

  RoomItem({
    required this.conversation,
    this.latestMessage,
  });
}

//Helper class.
class LatestMessage {
  String sender;
  String body;
  int originServerTs;

  LatestMessage({
    required this.sender,
    required this.body,
    required this.originServerTs,
  });
}

class ChatListController extends GetxController {
  List<RoomItem> roomItems = [];
  bool initialLoaded = false;

  // ignore: always_declare_return_types
  void updateList(List<Conversation> convos, String userId) {
    if (!initialLoaded) {
      initialLoaded = true;
    }
    update(['chatlist']);
    List<RoomItem> newRoomItems = [];
    for (Conversation convo in convos) {
      String roomId = convo.getRoomId();
      int oldIndex =
          roomItems.indexWhere((x) => x.conversation.getRoomId() == roomId);
      RoomMessage? msg = convo.latestMessage();
      if (msg == null) {
        // prevent latest message from deleting
        RoomItem newRoomItem = RoomItem(
          conversation: convo,
          latestMessage:
              oldIndex == -1 ? null : roomItems[oldIndex].latestMessage,
        );
        newRoomItems.add(newRoomItem);
        continue;
      }
      RoomItem newRoomItem = RoomItem(
        conversation: convo,
        latestMessage: LatestMessage(
          sender: msg.sender(),
          body: msg.body(),
          originServerTs: msg.originServerTs(),
        ),
      );
      newRoomItems.add(newRoomItem);
    }
    roomItems = newRoomItems;
    update(['chatlist']);
  }

  void sortList(int from, int to, RoomItem item) {
    roomItems
      ..removeAt(from)
      ..insert(to, item);
    update(['chatlist']);
  }
}
