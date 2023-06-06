import 'dart:async';

import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/controllers/chat_room_controller.dart';
import 'package:acter/features/chat/models/joined_room.dart';
import 'package:acter/features/chat/models/chat_list_state.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show
        Client,
        Conversation,
        FfiListConversation,
        FfiListInvitation,
        RoomId,
        TypingEvent;
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

final chatListProvider =
    StateNotifierProvider<ChatListNotifier, ChatListState>((ref) {
  final client = ref.watch(clientProvider);
  return ChatListNotifier(ref, client: client!);
});

class ChatListNotifier extends StateNotifier<ChatListState> {
  final Ref ref;
  final Client client;

  ChatListNotifier(this.ref, {required this.client})
      : super(const ChatListState()) {
    _init();
  }

  void _init() {
    StreamSubscription<FfiListConversation>? _convosSubscription;
    StreamSubscription<FfiListInvitation>? _invitesSubscription;
    StreamSubscription<TypingEvent>? _typingSubscription;
    // Conversations stream
    _convosSubscription = client.conversationsRx().listen((event) {
      List<JoinedRoom> tempState = [];
      if (state.joinedRooms.isNotEmpty) {
        state = state.copyWith(joinedRooms: tempState);
      }
      for (Conversation convo in event.toList()) {
        RoomId roomId = convo.getRoomId();
        int pos = state.joinedRooms.indexWhere((x) {
          return x.conversation.getRoomId() == roomId;
        });

        JoinedRoom newItem = JoinedRoom(conversation: convo);
        if (pos == -1) {
          newItem.latestMessage = convo.latestMessage();
        } else {
          if (state.joinedRooms[pos].avatar != null) {
            newItem.avatar = state.joinedRooms[pos].avatar;
          }
          if (state.joinedRooms[pos].displayName != null) {
            newItem.displayName = state.joinedRooms[pos].displayName;
          }
          newItem.latestMessage = state.joinedRooms[pos].latestMessage;
          newItem.typingUsers = state.joinedRooms[pos].typingUsers;
        }

        if (newItem.latestMessage != null) {
          debugPrint(
            'timestamp is ${newItem.latestMessage!.eventItem()!.originServerTs()}',
          );
        }
        tempState.add(newItem);
        state = state.copyWith(joinedRooms: tempState);
      }
      tempState.sort((a, b) {
        if (a.latestMessage != null && b.latestMessage != null) {
          return b.latestMessage!
              .eventItem()!
              .originServerTs()
              .compareTo(a.latestMessage!.eventItem()!.originServerTs());
        } else {
          return 0;
        }
      });
      tempState.reversed;
      state = state.copyWith(joinedRooms: tempState, searchData: tempState);

      if (!state.initialLoaded) {
        state = state.copyWith(initialLoaded: true); // used for rendering
      }
    });

    // Invitations stream
    _invitesSubscription = client.invitationsRx().listen((event) {
      state = state.copyWith(invitations: event.toList());
    });

    // Typing notification stream
    _typingSubscription = client.typingEventRx()?.listen((event) {
      List<JoinedRoom> tempState = [];
      RoomId roomId = event.roomId();
      int idx = state.joinedRooms.indexWhere((x) {
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
        tempState = state.joinedRooms;
        tempState[idx].typingUsers = typingUsers;
        state = state.copyWith(joinedRooms: tempState);
      } else if (roomId == currentRoomId) {
        // we are in chat room page
        roomController.typingUsers = typingUsers;
        roomController.update(['typing indicator']);
      }
    });
    ref.onDispose(() {
      _convosSubscription!.cancel();
      _invitesSubscription!.cancel();
      _typingSubscription!.cancel();
    });
  }

  void searchRoom(String data) {
    List<JoinedRoom> tempState = [];
    state = state.copyWith(searchData: tempState);
    var name = '';

    if (data.isNotEmpty) {
      for (var element in state.joinedRooms) {
        name = element.displayName!;
        if (name.toLowerCase().contains(data.toLowerCase())) {
          tempState.add(element);
          state = state.copyWith(searchData: tempState);
        }
      }
    } else {
      state = state.copyWith(searchData: state.joinedRooms);
    }
  }

  void moveItem(int from, int to) {
    final List<JoinedRoom> tempState = state.joinedRooms;
    JoinedRoom item = state.joinedRooms.removeAt(from);
    tempState.insert(to, item);
    state = state.copyWith(joinedRooms: tempState);
  }

  void toggleSearchView() {
    state = state.copyWith(showSearch: !state.showSearch);
  }
}
