import 'dart:async';

import 'package:effektio/controllers/chat_room_controller.dart';
import 'package:effektio/widgets/AppCommon.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show Client, Conversation, FfiListConversation, RoomMessage, TypingEvent;
import 'package:flutter/foundation.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
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
  Client client;
  late String userId;
  List<RoomItem> roomItems = [];
  List<types.User> typingUsers = [];
  bool initialLoaded = false;
  String? currentRoomId;
  StreamSubscription<FfiListConversation>? convosReceiver;
  StreamSubscription<TypingEvent>? typingReceiver;
  StreamSubscription<RoomMessage>? messageReceiver;

  ChatListController({required this.client}) : super();

  @override
  Future<void> onInit() async {
    super.onInit();
    userId = (await client.userId()).toString();
    if (!client.isGuest()) {
      convosReceiver = client.conversationsRx().listen((event) {
        updateList(event.toList(), userId);
      });
      typingReceiver = client.typingEventRx()?.listen((event) {
        String roomId = event.roomId();
        List<String> userIds = [];
        for (final userId in event.userIds()) {
          userIds.add(userId.toDartString());
        }
        for (var id in userIds) {
          types.User typingUser = types.User(
            id: id,
            firstName: getNameFromId(id),
          );
          typingUsers.add(typingUser);
        }
        if (Get.isRegistered<ChatRoomController>()) {
          if (roomId == currentRoomId) {
            update(['typing indicator']);
            Future.delayed(const Duration(seconds: 4), () {
              typingUsers.clear();
              update(['typing indicator']);
            });
          }
        } else {
          setCurrentRoomId(roomId);
          if (currentRoomId != null) {
            update(['$currentRoomId']);
            Future.delayed(const Duration(seconds: 4), () {
              typingUsers.clear();
              setCurrentRoomId(null);
              update(['$currentRoomId']);
            });
          }
        }
        debugPrint('typing event ' + roomId + ': ' + userIds.join(', '));
      });
      messageReceiver = client.messageEventRx()?.listen((event) {
        if (currentRoomId != null) {
          ChatRoomController controller = Get.find<ChatRoomController>();
          if (event.sender() != userId) {
            controller.loadMessage(event);
          }
          update(['Chat']);
        }
      });
    }
  }

  @override
  void onClose() {
    convosReceiver?.cancel();
    typingReceiver?.cancel();
    messageReceiver?.cancel();
    super.onClose();
  }

  void setCurrentRoomId(String? roomId) {
    currentRoomId = roomId;
  }

  // ignore: always_declare_return_types
  void updateList(List<Conversation> convos, String userId) {
    if (!initialLoaded) {
      initialLoaded = true;
    }
    update(['chatlist']);
    List<RoomItem> newItems = [];
    for (Conversation convo in convos) {
      String roomId = convo.getRoomId();
      int oldIndex =
          roomItems.indexWhere((x) => x.conversation.getRoomId() == roomId);
      RoomMessage? msg = convo.latestMessage();
      if (msg == null) {
        // prevent latest message from deleting
        RoomItem newItem = RoomItem(
          conversation: convo,
          latestMessage:
              oldIndex == -1 ? null : roomItems[oldIndex].latestMessage,
        );
        newItems.add(newItem);
        continue;
      }
      RoomItem newItem = RoomItem(
        conversation: convo,
        latestMessage: LatestMessage(
          sender: msg.sender(),
          body: msg.body(),
          originServerTs: msg.originServerTs(),
        ),
      );
      newItems.add(newItem);
    }
    roomItems = newItems;
    update(['chatlist']);
  }

  void moveItem(int from, int to) {
    RoomItem item = roomItems.removeAt(from);
    roomItems.insert(to, item);
    update(['chatlist']);
  }
}
