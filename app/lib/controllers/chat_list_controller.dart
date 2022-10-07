import 'dart:async';

import 'package:effektio/controllers/chat_room_controller.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show
        Client,
        Conversation,
        FfiListConversation,
        InvitationEvent,
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
  late String userId;
  List<JoinedRoom> joinedRooms = [];
  List<InvitationEvent> invitationEvents = [];
  bool initialLoaded = false;
  String? _currentRoomId;
  StreamSubscription<FfiListConversation>? _convosSubscription;
  StreamSubscription<TypingEvent>? _typingSubscription;
  StreamSubscription<RoomMessage>? _messageSubscription;

  ChatListController({required this.client}) : super() {
    userId = client.userId().toString();
  }

  @override
  void onInit() {
    super.onInit();
    if (!client.isGuest()) {
      _convosSubscription = client.conversationsRx().listen((event) {
        updateList(event.toList(), userId);
      });
      _typingSubscription = client.typingEventRx()?.listen((event) {
        String roomId = event.roomId();
        List<String> userIds = [];
        for (final userId in event.userIds()) {
          userIds.add(userId.toDartString());
        }
        debugPrint('typing event ' + roomId + ': ' + userIds.join(', '));
      });
      _messageSubscription = client.messageEventRx()?.listen((event) {
        if (_currentRoomId != null) {
          ChatRoomController controller = Get.find<ChatRoomController>();
          if (event.sender() != userId) {
            controller.loadMessage(event);
          }
          update(['Chat']);
        }
      });
      client.getInvitedRooms().then((events) {
        invitationEvents = events.toList();
        client.invitationEventRx()?.listen((event) {
          debugPrint('invited event: ' + event.roomName());
          int index = invitationEvents.indexWhere((x) {
            return x.roomId() == event.roomId();
          });
          if (index == -1) {
            invitationEvents.insert(0, event);
          } else {
            invitationEvents.removeAt(index);
          }
          update(['Chat']);
        });
      });
    }
  }

  @override
  void onClose() {
    _convosSubscription?.cancel();
    _typingSubscription?.cancel();
    _messageSubscription?.cancel();
    super.onClose();
  }

  void setCurrentRoomId(String? roomId) {
    _currentRoomId = roomId;
  }

  void updateList(List<Conversation> convos, String userId) {
    if (!initialLoaded) {
      initialLoaded = true;
    }
    update(['chatlist']);
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
    int index = invitationEvents.indexWhere((x) => x.roomId() == roomId);
    invitationEvents.removeAt(index);
    // add item to joined list
    var convo = await client.conversation(roomId);
    JoinedRoom newItem = JoinedRoom(conversation: convo);
    joinedRooms.insert(0, newItem);
    update(['chatlist']);
  }

  Future<void> rejectInvitation(String roomId) async {
    await client.rejectInvitation(roomId);
    // remove item from invited list
    int index = invitationEvents.indexWhere((x) => x.roomId() == roomId);
    invitationEvents.removeAt(index);
    // ignore the invited event
    update(['chatlist']);
  }
}
