import 'dart:async';

import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/controllers/chat_room_controller.dart';
import 'package:acter/features/chat/models/chat_list_state/chat_list_state.dart';
import 'package:acter/features/chat/models/joined_room/joined_room.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Convo, FfiListConvo, RoomId, TypingEvent;
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

class ChatListNotifier extends StateNotifier<ChatListState> {
  final Ref ref;

  ChatListNotifier(this.ref)
      : super(
          const ChatListState(
            initialLoaded: false,
            showSearch: false,
            searchData: [],
          ),
        ) {
    _init();
  }

  void _init() async {
    final client = ref.read(clientProvider)!;

    ///FIXME: This provider doesn't fetch latest messages in convo for some reason.
    // final convos = await ref.read(chatsProvider.future);
    /// Using convo stream then...
    StreamSubscription<FfiListConvo>? _convosSubscription;
    _convosSubscription = client.convosRx().listen((event) async {
      // FIXME: Maybe have CRUD possibility here instead of whole list reset
      ref.read(joinedRoomListProvider.notifier).reset();
      for (Convo convo in event.toList()) {
        final convoProfile = convo.getProfile();
        var dispName = await convoProfile.getDisplayName();
        RoomId r1 = convo.getRoomId();
        String r2 = r1.toString();
        String name = dispName.text() ?? r2;
        JoinedRoom newItem = JoinedRoom(
          id: r2,
          convo: convo,
          latestMessage: convo.latestMessage(),
          displayName: name,
        );
        if (newItem.latestMessage != null) {
          debugPrint(
            'latest message timestamp: ${newItem.latestMessage!.eventItem()!.originServerTs()}',
          );
        }
        ref.read(joinedRoomListProvider.notifier).addRoom(newItem);
      }
    });
    // await call so the update occurs in list from convos
    await Future.delayed(const Duration(milliseconds: 200), () {});

    ref.read(joinedRoomListProvider.notifier).sortRooms();
    final roomList = ref.read(joinedRoomListProvider);
    state = state.copyWith(
      searchData: roomList,
      initialLoaded: true,
      showSearch: false,
    );
    ref.onDispose(() {
      _convosSubscription?.cancel();
    });
    // start listener streams
    _typingEventStream();
  }

  // Typing notification stream
  void _typingEventStream() {
    final client = ref.read(clientProvider)!;
    StreamSubscription<TypingEvent>? _typingSubscription;
    final roomList = ref.read(joinedRoomListProvider);
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
      var roomController = Get.find<ChatRoomController>();
      RoomId? currentRoomId = roomController.currentRoomId();
      if (currentRoomId == null) {
        // we are in chat list page
        List<JoinedRoom> tempState = roomList;
        tempState[idx] = tempState[idx].copyWith(typingUsers: typingUsers);
        ref.read(joinedRoomListProvider.notifier).removeRoom(idx);
        ref
            .read(joinedRoomListProvider.notifier)
            .insertRoom(idx, tempState[idx]);
      } else if (roomId == currentRoomId) {
        // we are in chat room page
        roomController.typingUsers = typingUsers;
        roomController.update(['typing indicator']);
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
    final joinedRooms = ref.read(joinedRoomListProvider);

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
    ref.read(joinedRoomListProvider.notifier).removeRoom(from);
    ref
        .read(joinedRoomListProvider.notifier)
        .insertRoom(to, ref.read(joinedRoomListProvider)[from]);
  }

  void toggleSearchView() {
    state = state.copyWith(showSearch: !state.showSearch);
  }
}
