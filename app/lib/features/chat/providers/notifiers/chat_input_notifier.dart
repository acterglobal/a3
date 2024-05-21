import 'package:acter/features/chat/utils.dart';
import 'package:acter/features/chat/models/chat_input_state/chat_input_state.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:html/parser.dart';
import 'package:riverpod/riverpod.dart';

class ChatInputNotifier extends StateNotifier<ChatInputState> {
  ChatInputNotifier() : super(const ChatInputState());

  void emojiPickerVisible(bool value) =>
      state = state.copyWith(emojiPickerVisible: value);

  void addMention(String displayName, String authorId) {
    final mentions = Map.of(state.mentions);
    mentions[displayName] = authorId;
    state = state.copyWith(mentions: mentions);
  }

  void setReplyToMessage(Message message) {
    state = state.copyWith(
      selectedMessage: message,
      selectedMessageState: SelectedMessageState.replyTo,
    );
  }

  void updateMessage(String value) {
    state = state.copyWith(message: value);
  }

  void setEditMessage(Message message) {
    final Map<String, String> mentions = {};
    String messageBodyText = '';

    if (message is TextMessage) {
      // Parse String Data to HTML document
      final document = parse(message.text);

      if (document.body != null) {
        // Get message data
        String msg = message.text.trim();

        // Get list of 'A Tags' values
        final aTagElementList = document.getElementsByTagName('a');

        for (final aTagElement in aTagElementList) {
          final userMentionMessageData =
              parseUserMentionMessage(msg, aTagElement);
          msg = userMentionMessageData.parsedMessage;

          // Update mentions data
          mentions[userMentionMessageData.displayName] =
              userMentionMessageData.userName;
        }

        // Parse data
        final messageDocument = parse(msg);
        messageBodyText = messageDocument.body?.text ?? '';
      }
    }
    state = state.copyWith(
      selectedMessage: message,
      selectedMessageState: SelectedMessageState.edit,
      mentions: mentions,
      message: messageBodyText,
    );
  }

  void setActionsMessage(Message message) {
    state = state.copyWith(
      selectedMessage: message,
      selectedMessageState: SelectedMessageState.actions,
    );
  }

  void unsetActions() {
    if (state.selectedMessageState == SelectedMessageState.actions) {
      state = state.copyWith(
        selectedMessage: null,
        selectedMessageState: SelectedMessageState.none,
      );
    }
  }

  void unsetSelectedMessage() {
    state = state.copyWith(
      selectedMessage: null,
      selectedMessageState: SelectedMessageState.none,
    );
  }

  void startSending() {
    state = state.copyWith(sendingState: SendingState.sending);
  }

  void sendingFailed() {
    // reset the state;
    state = state.copyWith(sendingState: SendingState.preparing);
  }

  void messageSent() {
    // reset the state;
    state = state.copyWith(
      sendingState: SendingState.preparing,
      selectedMessage: null,
      selectedMessageState: SelectedMessageState.none,
      mentions: {},
    );
  }
}
