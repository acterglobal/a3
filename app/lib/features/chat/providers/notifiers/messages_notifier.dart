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
    if (to < newState.length) {
      newState.insert(to, m);
    } else {
      newState.add(m);
    }
    state = newState;
  }

  void replaceMessage(int index, types.Message m) {
    if (index < state.length) {
      List<types.Message> newState = [...state];
      newState[index] = m;
      state = newState;
    }
  }

  void removeMessage(int idx) {
    if (idx < state.length) {
      List<types.Message> newState = [...state];
      newState.removeAt(idx);
      state = newState;
    }
  }

  void reset() {
    state.clear();
  }
}
