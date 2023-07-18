import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class MessagesNotifier extends StateNotifier<List<types.Message>> {
  MessagesNotifier() : super([]);
  // Messages CRUD
  void addMessage(types.Message m) {
    state = [...state, m];
  }

  void insertMessage(int to, types.Message m) {
    List<types.Message> newState = [...state];
    newState[to] = m;
    state = newState;
  }

  void replaceMessage(int index, types.Message m) {
    state = List<types.Message>.of(state)..replaceRange(index, index, [m]);
  }

  void removeMessage(int idx) {
    state = [
      for (final message in state)
        if (state[idx] != message) message
    ];
  }

  void reset() {
    state = [];
  }
}
