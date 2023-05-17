import 'dart:async';

import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/controllers/chat_room_controller.dart';
import 'package:acter/models/JoinedRoom.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show
        Client,
        Conversation,
        FfiListConversation,
        FfiListInvitation,
        Invitation,
        RoomId,
        TypingEvent;
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:get/get.dart';

class ChatListController extends GetxController {
  Client client;

  List<JoinedRoom> joinedRooms = [];
  List<Invitation> invitations = [];
  bool showSearch = false;
  List<JoinedRoom> searchData = [];
  bool initialLoaded = false;
  StreamSubscription<FfiListConversation>? _convosSubscription;
  StreamSubscription<FfiListInvitation>? _invitesSubscription;
  StreamSubscription<TypingEvent>? _typingSubscription;
  TextEditingController searchController = TextEditingController();

  ChatListController({required this.client}) : super();

  @override
  void onInit() {
    super.onInit();

    _convosSubscription = client.conversationsRx().listen((event) {
      joinedRooms.clear();
      for (Conversation convo in event.toList()) {
        RoomId roomId = convo.getRoomId();
        int pos = joinedRooms.indexWhere((x) {
          return x.conversation.getRoomId() == roomId;
        });

        JoinedRoom newItem = JoinedRoom(conversation: convo);
        if (pos == -1) {
          newItem.latestMessage = convo.latestMessage();
        } else {
          if (joinedRooms[pos].avatar != null) {
            newItem.avatar = joinedRooms[pos].avatar;
          }
          if (joinedRooms[pos].displayName != null) {
            newItem.displayName = joinedRooms[pos].displayName;
          }
          newItem.latestMessage = joinedRooms[pos].latestMessage;
          newItem.typingUsers = joinedRooms[pos].typingUsers;
        }

        if (newItem.latestMessage != null) {
          debugPrint(
            'timestamp is ${newItem.latestMessage!.eventItem()!.originServerTs()}',
          );
        }

        joinedRooms.add(newItem);
      }

      joinedRooms.sort((a, b) {
        if (a.latestMessage != null && b.latestMessage != null) {
          return b.latestMessage!
              .eventItem()!
              .originServerTs()
              .compareTo(a.latestMessage!.eventItem()!.originServerTs());
        } else {
          return 0;
        }
      });

      joinedRooms.reversed;
      searchData.addAll(joinedRooms);

      if (!initialLoaded) {
        initialLoaded = true; // used for rendering
      }
      update(['chatlist']);
    });

    _invitesSubscription = client.invitationsRx().listen((event) {
      invitations = event.toList();
      update(['invited_list']);
    });

    _typingSubscription = client.typingEventRx()?.listen((event) {
      RoomId roomId = event.roomId();
      int idx = joinedRooms.indexWhere((x) {
        return x.conversation.getRoomId() == roomId;
      });
      if (idx == -1) {
        return;
      }
      List<types.User> typingUsers = [];
      for (var userId in event.userIds()) {
        if (userId == client.userId()) {
          // filter out my typing
          continue;
        }
        String uid = userId.toString();
        var user = types.User(
          id: uid,
          firstName: simplifyUserId(uid),
        );
        typingUsers.add(user);
      }
      // will not ignore empty list
      // because empty list means that peer stopped typing
      var roomController = Get.find<ChatRoomController>();
      RoomId? currentRoomId = roomController.currentRoomId();
      if (currentRoomId == null) {
        // we are in chat list page
        joinedRooms[idx].typingUsers = typingUsers;
        update(['chatroom-$roomId']);
      } else if (roomId == currentRoomId) {
        // we are in chat room page
        roomController.typingUsers = typingUsers;
        roomController.update(['typing indicator']);
      }
    });
  }

  @override
  void onClose() {
    _convosSubscription?.cancel();
    _invitesSubscription?.cancel();
    _typingSubscription?.cancel();

    super.onClose();
  }

  void moveItem(int from, int to) {
    JoinedRoom item = joinedRooms.removeAt(from);
    joinedRooms.insert(to, item);
    update(['chatlist']);
  }

  Future<void> setRoomProfile(Conversation room, JoinedRoom item) async {
    final profile = room.getProfile();
    if (profile.hasAvatar()) {
      item.avatar = profile.getThumbnail(62, 60);
    }
    item.displayName = await profile.getDisplayName();
  }

  void searchedData(String data, List<JoinedRoom> listOfRooms) {
    searchData.clear();
    var name = '';

    if (data.isNotEmpty) {
      for (var element in listOfRooms) {
        name = element.displayName!;
        if (name.toLowerCase().contains(data.toLowerCase())) {
          searchData.add(element);
        }
      }
      update(['chatlist']);
    } else {
      searchData.addAll(joinedRooms);
      update(['chatlist']);
    }
  }

  void toggleSearchView() {
    showSearch = !showSearch;
    update(['chatlist']);
  }
}
