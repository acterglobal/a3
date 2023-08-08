import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Convo;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_list_state.freezed.dart';

///Extension Method for easy comparison
extension ChatListStateGetters on ChatListState {
  bool get isLoading => this is _ChatListStateLoading;
}

@freezed
class ChatListState with _$ChatListState {
  ///Initial
  const factory ChatListState.initial() = _ChatListStateInitial;

  ///Loading
  const factory ChatListState.loading() = _ChatListStateLoading;

  ///Data
  const factory ChatListState.data({required List<Convo> chats}) =
      _ChatListStateData;

  ///Error
  const factory ChatListState.error([String? error]) = _ChatListStateError;
}
