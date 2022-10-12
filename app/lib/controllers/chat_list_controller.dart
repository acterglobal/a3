import 'dart:async';

import 'package:effektio/controllers/chat_room_controller.dart';
import 'package:effektio/widgets/AppCommon.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show Client, Conversation, FfiListConversation, RoomMessage, TypingEvent;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:get/get.dart';

//Helper class.
class RoomItem {
  Conversation conversation;
  LatestMessage? latestMessage;
  List<types.User> typingUsers = [];

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
  List<RoomItem> roomItems = [];
  bool initialLoaded = false;
  StreamSubscription<FfiListConversation>? _convosSubscription;
  StreamSubscription<TypingEvent>? _typingSubscription;

  ChatListController({required this.client}) : super();

  @override
  void onInit() {
    super.onInit();
    if (!client.isGuest()) {
      _convosSubscription = client.conversationsRx().listen((event) {
        // process the latest message here
        _updateList(event.toList());
      });
      _typingSubscription = client.typingEventRx()?.listen((event) {
        String roomId = event.roomId();
        int idx = roomItems.indexWhere((x) {
          return x.conversation.getRoomId() == roomId;
        });
        if (idx == -1) {
          return;
        }
        List<types.User> typingUsers = [];
        for (var userId in event.userIds()) {
          String uid = userId.toDartString();
          if (uid == client.userId().toString()) {
            // filter out my typing
            continue;
          }
          var user = types.User(
            id: uid,
            firstName: getNameFromId(uid),
          );
          typingUsers.add(user);
        }
        // will not ignore empty list
        // because empty list means that peer stopped typing
        var roomController = Get.find<ChatRoomController>();
        String? currentRoomId = roomController.currentRoomId();
        if (currentRoomId == null) {
          // we are in chat list page
          roomItems[idx].typingUsers = typingUsers;
          update([roomId]);
        } else if (roomId == currentRoomId) {
          // we are in chat room page
          roomController.typingUsers = typingUsers;
          update(['typing indicator']);
        }
      });
    }
  }

  @override
  void onClose() {
    _convosSubscription?.cancel();
    _typingSubscription?.cancel();
    super.onClose();
  }

  void _updateList(List<Conversation> convos) {
    if (!initialLoaded) {
      initialLoaded = true;
    }
    List<RoomItem> newItems = [];
    for (Conversation convo in convos) {
      RoomItem newItem = RoomItem(conversation: convo);
      String roomId = convo.getRoomId();
      int idx = roomItems.indexWhere((x) {
        return x.conversation.getRoomId() == roomId;
      });
      RoomMessage? msg = convo.latestMessage();
      if (msg == null) {
        // prevent latest message from deleting
        if (idx != -1) {
          newItem.latestMessage = roomItems[idx].latestMessage;
        }
      } else {
        newItem.latestMessage = LatestMessage(
          sender: msg.sender(),
          body: msg.body(),
          originServerTs: msg.originServerTs(),
        );
      }
      if (idx != -1) {
        newItem.typingUsers = roomItems[idx].typingUsers;
      }
      newItems.add(newItem);
    }
    roomItems = newItems;
    if (!initialLoaded) {
      initialLoaded = true;
    }
    update(['chatlist']);
  }

  void moveItem(int from, int to) {
    RoomItem item = roomItems.removeAt(from);
    roomItems.insert(to, item);
    update(['chatlist']);
  }
}
