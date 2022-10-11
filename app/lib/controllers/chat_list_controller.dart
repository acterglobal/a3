import 'dart:async';

import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show
        Client,
        Conversation,
        FfiListConversation,
        FfiListInvitation,
        Invitation,
        RoomMessage,
        TypingEvent;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

//Helper class.
class JoinedRoom {
  Conversation conversation;
  LatestMessage? latestMessage;

  JoinedRoom({
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
  List<JoinedRoom> joinedRooms = [];
  List<Invitation> invitations = [];
  bool initialLoaded = false;
  StreamSubscription<FfiListConversation>? _convosSubscription;
  StreamSubscription<FfiListInvitation>? _invitesSubscription;
  StreamSubscription<TypingEvent>? _typingSubscription;

  ChatListController({required this.client}) : super();

  @override
  void onInit() {
    super.onInit();
    if (!client.isGuest()) {
      _convosSubscription = client.conversationsRx().listen((event) {
        _updateList(event.toList());
      });
      _invitesSubscription = client.invitationsRx().listen((event) {
        invitations = event.toList();
        update(['invited_list']);
      });
      _typingSubscription = client.typingEventRx()?.listen((event) {
        String roomId = event.roomId();
        List<String> userIds = [];
        for (var userId in event.userIds()) {
          userIds.add(userId.toDartString());
        }
        debugPrint('typing event ' + roomId + ': ' + userIds.join(', '));
      });
    }
  }

  @override
  void onClose() {
    _convosSubscription?.cancel();
    _invitesSubscription?.cancel();
    _typingSubscription?.cancel();
    super.onClose();
  }

  void _updateList(List<Conversation> convos) {
    if (!initialLoaded) {
      initialLoaded = true;
    }
    List<JoinedRoom> newItems = [];
    for (Conversation convo in convos) {
      String roomId = convo.getRoomId();
      int oldIndex = joinedRooms.indexWhere((x) {
        return x.conversation.getRoomId() == roomId;
      });
      RoomMessage? msg = convo.latestMessage();
      if (msg == null) {
        // prevent latest message from deleting
        if (oldIndex == -1) {
          JoinedRoom newItem = JoinedRoom(conversation: convo);
          newItems.add(newItem);
        } else {
          JoinedRoom newItem = JoinedRoom(
            conversation: convo,
            latestMessage: joinedRooms[oldIndex].latestMessage,
          );
          newItems.add(newItem);
        }
        continue;
      }
      JoinedRoom newItem = JoinedRoom(
        conversation: convo,
        latestMessage: LatestMessage(
          sender: msg.sender(),
          body: msg.body(),
          originServerTs: msg.originServerTs(),
        ),
      );
      newItems.add(newItem);
    }
    joinedRooms = newItems;
    update(['chatlist']);
  }

  void moveItem(int from, int to) {
    JoinedRoom item = joinedRooms.removeAt(from);
    joinedRooms.insert(to, item);
    update(['chatlist']);
  }

  Future<void> acceptInvitation(String roomId) async {
    await client.acceptInvitation(roomId);
    // remove item from invited list
    // int index = invitations.indexWhere((x) => x.roomId() == roomId);
    // invitations.removeAt(index);
    // update(['chatlist']);
  }

  Future<void> rejectInvitation(String roomId) async {
    await client.rejectInvitation(roomId);
    // remove item from invited list
    // int index = invitations.indexWhere((x) => x.roomId() == roomId);
    // invitations.removeAt(index);
    // update(['chatlist']);
  }
}
