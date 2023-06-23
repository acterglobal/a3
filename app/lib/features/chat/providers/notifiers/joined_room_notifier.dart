import 'package:acter/features/chat/models/joined_room/joined_room.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class JoinedRoomNotifier extends StateNotifier<List<JoinedRoom>> {
  JoinedRoomNotifier() : super([]);

  void addRoom(JoinedRoom item) {
    state = [...state, item];
  }

  void insertRoom(int to, JoinedRoom item) {
    List<JoinedRoom> newState = [...state];
    newState[to] = item;
    state = newState;
  }

  void removeRoom(int idx) {
    state = [
      for (final room in state)
        if (state[idx] != room) room
    ];
  }

  void sortRooms() {
    List<JoinedRoom> tempState = state;
    // rooms could contain RoomMessage as null, so handle null values differently.
    tempState.sort((a, b) {
      if (a.latestMessage == null) {
        return 1;
      }
      if (b.latestMessage == null) {
        return -1;
      } else {
        return b.latestMessage!
            .eventItem()!
            .originServerTs()
            .compareTo(a.latestMessage!.eventItem()!.originServerTs());
      }
    });
    state = tempState;
  }

  void reset() {
    state = [];
  }
}
