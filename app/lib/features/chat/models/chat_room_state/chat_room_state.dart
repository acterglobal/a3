import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' show Message;

part 'chat_room_state.freezed.dart';

///Extension Method for easy comparison
extension ChatRoomStateGetters on ChatRoomState {
  bool get isLoading => this is _ChatRoomStateLoading;
}

@freezed
class ChatRoomState with _$ChatRoomState {
  ///Initial
  const factory ChatRoomState.initial() = _ChatRoomStateInitial;

  ///Loading
  const factory ChatRoomState.loading() = _ChatRoomStateLoading;

  ///Data
  const factory ChatRoomState.data({required List<Message> messages}) =
      _ChatRoomStateData;

  ///Error
  const factory ChatRoomState.error([String? error]) = _ChatRoomStateError;
}
