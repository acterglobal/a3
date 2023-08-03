import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_room_state.freezed.dart';

///Extension Method for easy comparison
extension ChatRoomStateGetters on ChatRoomState {
  bool get isLoading => this is _ChatRoomStateLoading;
}

@freezed
class ChatRoomState with _$ChatRoomState {
  ///Loading
  const factory ChatRoomState.loading() = _ChatRoomStateLoading;

  ///Data
  const factory ChatRoomState.loaded() = _ChatRoomStateLoaded;

  ///Error
  const factory ChatRoomState.error([String? error]) = _ChatRoomStateError;
}
