import 'dart:async';
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

class TextMessageBuilder extends StatefulWidget {
  const TextMessageBuilder({
    Key? key,
    required this.message,
    this.onPreviewDataFetched,
    required this.controller,
    required this.messageWidth,
  }) : super(key: key);

  final types.TextMessage message;
  final void Function(types.TextMessage, types.PreviewData)?
      onPreviewDataFetched;
  final ChatRoomController controller;
  final int messageWidth;

  @override
  State<TextMessageBuilder> createState() => _TextMessageBuilderState();
}

class _TextMessageBuilderState extends State<TextMessageBuilder> {
  bool isLoading = true;

  void toggleLoading() {
    setState(() {
      isLoading = !isLoading;
    });
  }

  @override
  Widget build(BuildContext context) {
    //remove mx-reply tags.
    String parsedString = simplifyBody(widget.message.text);
    final urlRegexp = RegExp(
      r'https://matrix\.to/#/@[A-Za-z0-9]+:[A-Za-z0-9]+\.[A-Za-z0-9]+',
      caseSensitive: false,
    );
    //will return empty if link is other than reply
    final matches = urlRegexp.allMatches(parsedString);

    if (matches.isEmpty) {
      return _linkPreview(
        widget.message.author,
        widget.messageWidth.toDouble(),
        context,
        parsedString,
      );
    }
    return textWidget();
  }

  Widget textWidget() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: sqrt(widget.message.metadata!['messageLength']) * 38.5,
        maxHeight: double.infinity,
      ),
      child: Html(
        // ignore: prefer_single_quotes, unnecessary_string_interpolations
        data: """${widget.message.text}""",
        padding: const EdgeInsets.all(8),
        defaultTextStyle: const TextStyle(color: ChatTheme01.chatBodyTextColor),
      ),
    );
  }

  Widget _linkPreview(
    types.User user,
    double width,
    BuildContext context,
    String parsedString,
  ) {
    return LinkPreview(
      metadataTitleStyle: user.id == widget.message.author.id
          ? const EffektioChatTheme().sentMessageLinkTitleTextStyle
          : const EffektioChatTheme().receivedMessageLinkTitleTextStyle,
      metadataTextStyle: user.id == widget.message.author.id
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
      previewData: widget.message.previewData,
      text: parsedString,
      onPreviewDataFetched: _onPreviewDataFetched,
      textWidget: textWidget(),
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  void _onPreviewDataFetched(types.PreviewData previewData) {
    if (widget.message.previewData == null) {
      widget.controller.handlePreviewDataFetched
          .call(widget.message, previewData);
    }
  }
}
