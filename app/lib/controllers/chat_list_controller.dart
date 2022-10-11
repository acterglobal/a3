import 'dart:async';

import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show Client, Conversation, FfiListConversation, RoomMessage, TypingEvent;
import 'package:flutter/foundation.dart';
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
        _loadItems(event.toList());
      });
      _typingSubscription = client.typingEventRx()?.listen((event) {
        List<String> userIds = [];
        for (var userId in event.userIds()) {
          userIds.add(userId.toDartString());
        }
        String roomId = event.roomId();
        debugPrint('typing event ' + roomId + ': ' + userIds.join(', '));
      });
    }
  }

  @override
  void onClose() {
    _convosSubscription?.cancel();
    _typingSubscription?.cancel();
    super.onClose();
  }

  void _loadItems(List<Conversation> convos) {
    List<RoomItem> newItems = [];
    for (Conversation convo in convos) {
      RoomMessage? msg = convo.latestMessage();
      if (msg == null) {
        // prevent latest message from deleting
        RoomItem newItem = RoomItem(
          conversation: convo,
          latestMessage: _getLatestMessage(convo.getRoomId()),
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
    if (!initialLoaded) {
      initialLoaded = true;
    }
    update(['chatlist']);
  }

  LatestMessage? _getLatestMessage(String roomId) {
    int index = roomItems.indexWhere((x) {
      return x.conversation.getRoomId() == roomId;
    });
    if (index != -1) {
      return roomItems[index].latestMessage;
    }
    return null;
  }

  void moveItem(int from, int to) {
    RoomItem item = roomItems.removeAt(from);
    roomItems.insert(to, item);
    update(['chatlist']);
  }
}
