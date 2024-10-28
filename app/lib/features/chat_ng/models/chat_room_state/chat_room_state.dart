import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_room_state.freezed.dart';

///Extension Method for easy comparison
extension ChatRoomLoadingStateGetters on ChatRoomLoadingState {
  bool get isLoading => this is _ChatRoomLoadingStateLoading;
}

@freezed
class ChatRoomLoadingState with _$ChatRoomLoadingState {
  ///Initial
  const factory ChatRoomLoadingState.initial() = _ChatRoomLoadingStateInitial;

  ///Loading
  const factory ChatRoomLoadingState.loading() = _ChatRoomLoadingStateLoading;

  ///Data
  const factory ChatRoomLoadingState.loaded() = _ChatRoomLoadingStateLoaded;

  ///Error
  const factory ChatRoomLoadingState.error([String? error]) =
      _ChatRoomLoadingStateError;
}

@freezed
class ChatRoomState with _$ChatRoomState {
  const ChatRoomState._();

  const factory ChatRoomState({
    @Default([]) List<String> messageList,
    @Default({}) Map<String, RoomMessage> messages,
    @Default(ChatRoomLoadingState.initial()) ChatRoomLoadingState loading,
    @Default(true) bool hasMore,
  }) = _ChatRoomState;

  RoomMessage? message(String uniqueId) => messages[uniqueId];

  ChatRoomState copyWithRemovedMessageAt(
    int idx,
    AnimatedListState? listState,
  ) {
    if (this.messageList.isEmpty) {
      return this;
    }
    final messageList = this.messageList.toList();
    final removedItem = messageList.removeAt(idx);
    final messages = Map.fromEntries(
      this.messages.entries.where((entry) => entry.key != removedItem),
    );
    listState?.removeItem(idx, (a, b) => const SizedBox.shrink());
    return copyWith(
      messageList: messageList,
      messages: messages,
    );
  }

  ChatRoomState copyWithNewMessageAt(
    int idx,
    RoomMessage m,
    AnimatedListState? listState,
  ) {
    final uniqueId = m.uniqueId();
    if (this.messageList.isEmpty) {
      listState?.insertItem(0);
      return copyWith(
        messageList: [uniqueId],
        messages: {uniqueId: m},
      );
    }
    final messageList = this.messageList.toList();
    messageList.insert(idx, uniqueId);

    final messages = Map.fromEntries(this.messages.entries);
    messages[uniqueId] = m;

    listState?.insertItem(idx);
    return copyWith(
      messageList: messageList,
      messages: messages,
    );
  }
}
