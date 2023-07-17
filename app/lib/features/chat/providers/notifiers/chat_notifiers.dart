import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/models/chat_data_state/chat_data_state.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Convo, TypingEvent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class ChatsNotifier extends StateNotifier<ChatDataState> {
  final Ref ref;
  final AsyncValue<List<Convo>> asyncChats;
  ChatsNotifier({required this.ref, required this.asyncChats})
      : super(const ChatDataState.initial()) {
    _loadUp();
  }

  void _loadUp() async {
    state = asyncChats.when(
      data: (rooms) => ChatDataState.data(chats: rooms),
      error: (e, s) => ChatDataState.error(e.toString()),
      loading: () => const ChatDataState.loading(),
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
      state = ChatDataState.data(chats: temp);
    } else {
      temp = asyncChats.requireValue;
      state = ChatDataState.data(chats: temp);
    }
  }

  void moveItem(int from, int to) {
    var temp = asyncChats.requireValue;
    temp.removeAt(from);
    temp.insert(to, temp[from]);
    state = ChatDataState.data(chats: temp);
  }
}
