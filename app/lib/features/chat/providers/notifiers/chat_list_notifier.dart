import 'package:acter/features/chat/models/chat_list_state/chat_list_state.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Convo;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatListNotifier extends StateNotifier<ChatListState> {
  final Ref ref;
  final AsyncValue<List<Convo>> asyncChats;
  ChatListNotifier({required this.ref, required this.asyncChats})
      : super(const ChatListState.initial()) {
    _loadUp();
  }

  void _loadUp() async {
    state = asyncChats.when(
      data: (rooms) => ChatListState.data(chats: rooms),
      error: (e, s) => ChatListState.error(e.toString()),
      loading: () => const ChatListState.loading(),
    );
  }

  void searchRoom(String data) async {
    List<Convo> temp = [];
    if (data.isNotEmpty) {
      for (var element in asyncChats.requireValue) {
        final name = await element
                .getProfile()
                .getDisplayName()
                .then((value) => value.text()) ??
            element.getRoomIdStr();
        if (name.toLowerCase().contains(data.toLowerCase())) {
          temp.add(element);
        }
      }
      state = ChatListState.data(chats: temp);
    } else {
      temp = asyncChats.requireValue;
      state = ChatListState.data(chats: temp);
    }
  }

  void moveItem(int from, int to) {
    var temp = asyncChats.requireValue;
    temp.removeAt(from);
    temp.insert(to, temp[from]);
    state = ChatListState.data(chats: temp);
  }
}
