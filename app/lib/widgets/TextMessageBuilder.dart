import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:effektio/common/store/themes/ChatTheme.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/chat_room_controller.dart';
import 'package:effektio/widgets/AppCommon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:get/get.dart';

class TextMessageBuilder extends StatelessWidget {
  TextMessageBuilder({
    Key? key,
    required this.message,
    this.onPreviewDataFetched,
    required this.messageWidth,
  }) : super(key: key);

  final types.TextMessage message;
  final void Function(types.TextMessage, types.PreviewData)?
      onPreviewDataFetched;
  final int messageWidth;
  final controller = Get.find<ChatRoomController>();
  @override
  Widget build(BuildContext context) {
    //remove mx-reply tags.
    String parsedString = simplifyBody(message.text);
    final urlRegexp = RegExp(
      r'https://matrix\.to/#/@[A-Za-z0-9]+:[A-Za-z0-9]+\.[A-Za-z0-9]+',
      caseSensitive: false,
    );
    final bool enlargeEmoji = message.metadata!['enlargeEmoji'];
    //will return empty if link is other than mention
    final matches = urlRegexp.allMatches(parsedString);
    if (matches.isEmpty) {
      return LinkPreview(
        metadataTitleStyle: controller.userId == message.author.id
            ? const EffektioChatTheme().sentMessageLinkTitleTextStyle
            : const EffektioChatTheme().receivedMessageLinkTitleTextStyle,
        metadataTextStyle: controller.userId == message.author.id
            ? const EffektioChatTheme().sentMessageLinkDescriptionTextStyle
            : const EffektioChatTheme().receivedMessageLinkDescriptionTextStyle,
        enableAnimation: true,
        imageBuilder: (image) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: image,
                maxHeightDiskCache: 256,
              ),
            ),
          );
        },
        previewData: message.previewData,
        text: parsedString,
        onPreviewDataFetched: _onPreviewDataFetched,
        textWidget: _TextWidget(
          controller: controller,
          message: message,
          enlargeEmoji: message.metadata!['enlargeEmoji'],
        ),
        width: messageWidth.toDouble(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      );
    }
    return _TextWidget(
      controller: controller,
      message: message,
      enlargeEmoji: enlargeEmoji,
    );
  }

  void _onPreviewDataFetched(types.PreviewData previewData) {
    final controller = Get.find<ChatRoomController>();
    if (message.previewData == null) {
      controller.handlePreviewDataFetched.call(message, previewData);
    }
  }
}

class _TextWidget extends StatelessWidget {
  const _TextWidget({
    required this.controller,
    required this.message,
    required this.enlargeEmoji,
  });
  final ChatRoomController controller;
  final types.TextMessage message;
  final bool enlargeEmoji;
  @override
  Widget build(BuildContext context) {
    final emojiTextStyle = controller.userId == message.author.id
        ? EffektioChatTheme().sentEmojiMessageTextStyle
        : EffektioChatTheme().receivedEmojiMessageTextStyle;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: enlargeEmoji
            ? double.infinity
            : sqrt(message.metadata!['messageLength']) * 38.5,
        maxHeight: double.infinity,
      ),
      child: enlargeEmoji
          ? Text(
              message.text,
              style: emojiTextStyle,
            )
          : Html(
              // ignore: prefer_single_quotes, unnecessary_string_interpolations
              data: """${message.text}""",
              padding: const EdgeInsets.all(8),
              defaultTextStyle:
                  const TextStyle(color: ChatTheme01.chatBodyTextColor),
            ),
    );
  }
}
