import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show Client, Conversation, RoomMessage;
import 'package:get/get.dart';

//Helper class.
class RoomData {
  String roomId;
  Conversation conversation;
  RecentMessage? recentMessage;

  RoomData({
    required this.roomId,
    required this.conversation,
    this.recentMessage,
  });
}

//Helper class.
class RecentMessage {
  String sender;
  String body;
  int originServerTs;

  RecentMessage({
    required this.sender,
    required this.body,
    required this.originServerTs,
  });
}

class ChatListController extends GetxController {
  static ChatListController get instance =>
      Get.put<ChatListController>(ChatListController());
  late final String user;
  List<RoomData> roomDatas = [];
  bool initialLoaded = false;
  // ignore: always_declare_return_types
  init(Client client) async {
    var userId = await client.userId();
    user = userId.toString();
    client.conversationsRx().listen((event) {
      if (!initialLoaded) {
        initialLoaded = true;
      }
      update(['chatlist']);
      List<RoomData> newRoomDatas = [];
      for (Conversation convo in event.toList()) {
        String roomId = convo.getRoomId();
        int oldIndex = roomDatas.indexWhere((x) => x.roomId == roomId);
        RoomMessage? msg = convo.latestMessage();
        if (msg == null) {
          // prevent latest message from deleting
          RoomData newRoomData = RoomData(
            roomId: roomId,
            conversation: convo,
            recentMessage:
                oldIndex == -1 ? null : roomDatas[oldIndex].recentMessage,
          );
          newRoomDatas.add(newRoomData);
          continue;
        }
        RoomData newRoomData = RoomData(
          roomId: roomId,
          conversation: convo,
          recentMessage: RecentMessage(
            sender: msg.sender(),
            body: msg.body(),
            originServerTs: msg.originServerTs(),
          ),
        );
        newRoomDatas.add(newRoomData);
      }
      roomDatas = newRoomDatas;
      update(['chatlist']);
    });
  }

  void updateList(int from, int to, RoomData item) {
    roomDatas
      ..removeAt(from)
      ..insert(to, item);
    update(['chatlist']);
  }
}
