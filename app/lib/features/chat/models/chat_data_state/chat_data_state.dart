import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Conversation;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_data_state.freezed.dart';

///Extension Method for easy comparison
extension ChatListStateGetters on ChatDataState {
  bool get isLoading => this is _ChatDataStateLoading;
}

@freezed
class ChatDataState with _$ChatDataState {
  ///Initial
  const factory ChatDataState.initial() = _ChatDataStateInitial;

  ///Loading
  const factory ChatDataState.loading() = _ChatDataStateLoading;

  ///Data
  const factory ChatDataState.data({required List<Conversation> chats}) =
      _ChatDataStateData;

  ///Error
  const factory ChatDataState.error([String? error]) = _ChatDataStateError;
}
