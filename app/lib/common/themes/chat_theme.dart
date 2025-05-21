import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';

final defaultSenderChatBubbleGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    const Color.fromARGB(255, 58, 77, 183),
    const Color.fromARGB(255, 64, 99, 225),
    brandColor,
  ],
);

@immutable
class ActerChatTheme extends ChatTheme {
  final LinearGradient senderChatBubbleGradient;

  ActerChatTheme({
    LinearGradient? senderChatBubbleGradient,
    super.attachmentButtonIcon,
    super.attachmentButtonMargin,
    super.backgroundColor = const Color.fromRGBO(36, 38, 50, 0),
    super.dateDividerMargin = const EdgeInsets.only(bottom: 32, top: 16),
    super.dateDividerTextStyle = const TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w800,
      height: 1.333,
    ),
    super.deliveredIcon,
    super.documentIcon = const Icon(Atlas.file_thin, size: 18),
    super.emptyChatPlaceholderTextStyle = const TextStyle(
      color: neutral2,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    super.errorColor = error,
    super.errorIcon,
    super.inputBackgroundColor = const Color.fromRGBO(51, 53, 64, 0.4),
    super.inputBorderRadius = const BorderRadius.vertical(
      top: Radius.circular(0),
    ),
    super.inputContainerDecoration,
    super.inputMargin = EdgeInsets.zero,
    super.inputPadding = const EdgeInsets.symmetric(
      vertical: 5,
      horizontal: 14,
    ),
    super.inputTextColor = neutral7,
    super.inputTextCursorColor,
    super.inputTextDecoration = const InputDecoration(
      border: InputBorder.none,
      contentPadding: EdgeInsets.zero,
    ),
    super.inputTextStyle = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    super.inputElevation = 0,
    super.inputSurfaceTintColor = Colors.transparent,
    super.messageBorderRadius = 20,
    super.messageInsetsHorizontal = 20,
    super.messageInsetsVertical = 16,
    super.messageMaxWidth = 440,
    super.primaryColor = const Color(0xffFF8E00),
    super.receivedEmojiMessageTextStyle = const TextStyle(fontSize: 40),
    super.receivedMessageBodyBoldTextStyle,
    super.receivedMessageBodyCodeTextStyle,
    super.receivedMessageBodyLinkTextStyle,
    super.receivedMessageBodyTextStyle = const TextStyle(
      color: neutral7,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    super.receivedMessageCaptionTextStyle = const TextStyle(
      color: neutral7,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.333,
    ),
    super.receivedMessageDocumentIconColor = primary,
    super.receivedMessageLinkDescriptionTextStyle = const TextStyle(
      color: neutral7,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.428,
    ),
    super.receivedMessageLinkTitleTextStyle = const TextStyle(
      color: neutral7,
      fontSize: 14,
      fontWeight: FontWeight.w800,
      height: 1.375,
    ),
    super.secondaryColor = const Color.fromRGBO(51, 53, 64, 1),
    super.seenIcon,
    super.sendButtonIcon = const Icon(Atlas.paper_airplane),
    super.sendButtonMargin,
    super.sendingIcon,
    super.sentEmojiMessageTextStyle = const TextStyle(fontSize: 40),
    super.sentMessageBodyBoldTextStyle,
    super.sentMessageBodyCodeTextStyle,
    super.sentMessageBodyLinkTextStyle,
    super.sentMessageBodyTextStyle = const TextStyle(
      color: neutral7,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    super.sentMessageCaptionTextStyle = const TextStyle(
      color: neutral7WithOpacity,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.333,
    ),
    super.sentMessageDocumentIconColor = neutral7,
    super.sentMessageLinkDescriptionTextStyle = const TextStyle(
      color: neutral7,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.428,
    ),
    super.sentMessageLinkTitleTextStyle = const TextStyle(
      color: neutral7,
      fontSize: 14,
      fontWeight: FontWeight.w800,
      height: 1.375,
    ),
    super.statusIconPadding = const EdgeInsets.symmetric(horizontal: 4),
    super.userAvatarImageBackgroundColor = Colors.transparent,
    super.userAvatarNameColors = colors,
    super.userAvatarTextStyle = const TextStyle(
      color: neutral7,
      fontSize: 12,
      fontWeight: FontWeight.w800,
      height: 1.333,
    ),
    super.userNameTextStyle = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      height: 1.333,
    ),
    super.systemMessageTheme = const SystemMessageTheme(
      margin: EdgeInsets.zero,
      textStyle: TextStyle(),
    ),
    super.unreadHeaderTheme = const UnreadHeaderTheme(
      color: secondary,
      textStyle: TextStyle(
        color: neutral2,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.333,
      ),
    ),
    super.typingIndicatorTheme = const TypingIndicatorTheme(
      animatedCirclesColor: Color(0xFFFFFFFF),
      animatedCircleSize: 8.0,
      bubbleColor: Colors.transparent,
      countAvatarColor: Color(0xFFDA88A1),
      countTextColor: Color(0xFFFFFFFF),
      bubbleBorder: BorderRadius.all(Radius.circular(27.0)),
      multipleUserTextStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: neutral2,
      ),
    ),
  }) : senderChatBubbleGradient =
           senderChatBubbleGradient ?? defaultSenderChatBubbleGradient;
}
