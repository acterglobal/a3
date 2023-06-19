import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatMessagesNotifier extends StateNotifier<List<types.Message>> {
  ChatMessagesNotifier() : super([]);

  void addMessage(types.Message m) {
    state = [...state, m];
  }

  void removeMessage(int index) {
    state = [...state.where((element) => state[index] != element)];
  }
}
