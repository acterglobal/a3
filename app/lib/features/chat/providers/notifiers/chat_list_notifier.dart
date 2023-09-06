import 'package:acter/features/chat/models/chat_list_state/chat_list_state.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatListNotifier extends StateNotifier<ChatListState> {
  final Ref ref;
  final AsyncValue<List<Convo>> asyncChats;

  ChatListNotifier({
    required this.ref,
    required this.asyncChats,
  }) : super(const ChatListState.initial()) {
    _loadUp();
  }

  Future<void> _loadUp() async {
    state = asyncChats.when(
      data: (convos) => ChatListState.data(chats: [...convos]),
      error: (e, s) => ChatListState.error(e.toString()),
      loading: () => const ChatListState.loading(),
    );
  }

  Future<void> searchRoom(String? data) async {
    List<Convo> convos = [];
    if (data != null && data.isNotEmpty) {
      for (var convo in asyncChats.requireValue) {
        final name = await convo
                .getProfile()
                .getDisplayName()
                .then((value) => value.text()) ??
            convo.getRoomIdStr();
        if (name.toLowerCase().contains(data.toLowerCase())) {
          convos.add(convo);
        }
      }
      state = ChatListState.data(chats: convos);
    } else {
      convos = asyncChats.requireValue;
      state = ChatListState.data(chats: convos);
    }
  }

  void moveItem(int from, int to) {
    final convos = asyncChats.requireValue;
    final convo = convos.removeAt(from);
    convos.insert(to, convo);
    state = ChatListState.data(chats: convos);
  }

  // used to update UnableToDecrypt message
  void updateLatestMessage(RoomMessage msg) {
    final convos = asyncChats.requireValue;
    for (var i = 0; i < convos.length; i++) {
      final oldMsg = convos[i].latestMessage();
      if (oldMsg != null) {
        final eventItem = oldMsg.eventItem();
        if (eventItem != null) {
          if (eventItem.eventId() == msg.eventItem()?.eventId()) {
            final convo = convos.removeAt(i);
            convo.setLatestMessage(msg);
            convos.insert(i, convo);
            state = ChatListState.data(chats: convos);
            break;
          }
        }
      }
    }
  }
}
