import 'dart:async';

import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/models/chat_room_state/chat_room_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/controllers/chat_room_controller.dart';
import 'package:acter/features/chat/models/joined_room/joined_room.dart';
import 'package:acter/features/chat/models/chat_list_state/chat_list_state.dart';
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

class ChatListNotifier extends StateNotifier<ChatListState> {
  final Ref ref;
  final Client client;

  ChatListNotifier(this.ref, {required this.client})
      : super(const ChatListState()) {
    _init();
  }

  void _init() async {
    if (state.initialLoaded) {
      state = state.copyWith(initialLoaded: false);
    }
    final conversations = await ref.read(chatsProvider.future);
    for (var item in conversations) {
      String? roomName = await item
          .getProfile()
          .getDisplayName()
          .then((value) => value.text().toString());
      JoinedRoom room = JoinedRoom(
        id: item.getRoomId().toString(),
        conversation: item,
        latestMessage: item.latestMessage(),
        displayName: roomName ?? item.getRoomId().toString(),
      );
      ref.read(roomListProvider.notifier).addRoom(room);
    }
    state = state.copyWith(
      searchData: ref.read(roomListProvider),
      initialLoaded: true,
    );
    // start listener streams
    _convoStream();
    _invitationsStream();
    _typingEventStream();
  }

  // Conversations stream
  void _convoStream() {
    StreamSubscription<FfiListConversation>? _convosSubscription;
    _convosSubscription = client.conversationsRx().listen((event) {
      // FIXME: Maybe have CRUD possibility here instead of whole list reset
      // and reassignment?
      ref.read(roomListProvider.notifier).reset();
      for (Conversation convo in event.toList()) {
        JoinedRoom newItem = JoinedRoom(
          id: convo.getRoomId().toString(),
          conversation: convo,
          latestMessage: convo.latestMessage(),
        );
        if (newItem.latestMessage != null) {
          debugPrint(
            'timestamp is ${newItem.latestMessage!.eventItem()!.originServerTs()}',
          );
        }
        ref.read(roomListProvider.notifier).addRoom(newItem);
        ref.read(roomListProvider.notifier).sortRooms();
      }
    });
    // call stream close when provider isn't listened
    ref.onDispose(() {
      _convosSubscription?.cancel();
    });
  }

  // Invitations stream
  void _invitationsStream() {
    StreamSubscription<FfiListInvitation>? _invitesSubscription;
    _invitesSubscription = client.invitationsRx().listen((event) {
      ref.read(invitationListProvider.notifier).setList(event.toList());
    });
    // call stream close when provider isn't listened
    ref.onDispose(() {
      _invitesSubscription?.cancel();
    });
  }

  // Typing notification stream
  void _typingEventStream() {
    StreamSubscription<TypingEvent>? _typingSubscription;
    final roomList = ref.read(roomListProvider);
    _typingSubscription = client.typingEventRx()?.listen((event) {
      RoomId roomId = event.roomId();
      int idx = roomList.indexWhere((x) {
        return x.id == roomId.toString();
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
      RoomId? currentRoomId =
          ref.read(chatRoomProvider.notifier).currentRoomId();
      if (currentRoomId == null) {
        // we are in chat list page
        final List<JoinedRoom> tempState = roomList;
        tempState[idx] = tempState[idx].copyWith(typingUsers: typingUsers);
        ref.read(roomListProvider.notifier).removeRoom(idx);
        ref.read(roomListProvider.notifier).insertRoom(idx, tempState[idx]);
      } else if (roomId == currentRoomId) {
        // we are in chat room page
        ChatRoomState roomState = ref.read(chatRoomProvider);
        roomState = roomState.copyWith(typingUsers: typingUsers);
        ref.read(chatRoomProvider.notifier).state = roomState;
      }
    });
    // call stream close when provider isn't listened
    ref.onDispose(() {
      _typingSubscription?.cancel();
    });
  }

  void searchRoom(String data) async {
    List<JoinedRoom> tempState = [];
    state = state.copyWith(searchData: tempState);
    var name = '';
    final joinedRooms = ref.read(roomListProvider);

    if (data.isNotEmpty) {
      for (var element in joinedRooms) {
        name = element.displayName ?? element.id;
        if (name.toLowerCase().contains(data.toLowerCase())) {
          tempState.add(element);
          state = state.copyWith(searchData: tempState);
        }
      }
    } else {
      state = state.copyWith(searchData: joinedRooms);
    }
  }

  void moveItem(int from, int to) {
    ref.read(roomListProvider.notifier).removeRoom(from);
    ref
        .read(roomListProvider.notifier)
        .insertRoom(to, ref.read(roomListProvider)[from]);
  }

  void toggleSearchView() {
    state = state.copyWith(showSearch: !state.showSearch);
  }
}
