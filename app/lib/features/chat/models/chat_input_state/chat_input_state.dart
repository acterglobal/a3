import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show FfiBufferUint8;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_input_state.freezed.dart';

@freezed
class ChatInputState with _$ChatInputState {
  const factory ChatInputState({
    @Default({}) Map<String, String> usernames,
    @Default({}) Map<String, Future<FfiBufferUint8>> userAvatars,
    @Default({}) Map<String, String> messageTextMapMarkDown,
    @Default({}) Map<String, String> messageTextMapHtml,
    @Default([]) List<Map<String, dynamic>> mentionList,
    @Default(0) int emojiMessageIndex,
    @Default(null) String? emojiCurrentId,
    @Default(false) bool showReplyView,
    @Default(false) bool isSendButtonVisible,
    @Default(false) bool isEmojiContainerVisible,
    @Default(false) bool isEmojiVisible,
    @Default(false) bool isAttachmentVisible,
  }) = _ChatInputState;
}
