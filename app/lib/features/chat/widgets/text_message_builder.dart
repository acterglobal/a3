import 'dart:math';

import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:acter/common/themes/chat_theme.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TextMessageBuilder extends ConsumerStatefulWidget {
  final types.TextMessage message;
  final void Function(types.TextMessage, types.PreviewData)?
      onPreviewDataFetched;
  final int messageWidth;

  const TextMessageBuilder({
    Key? key,
    required this.message,
    this.onPreviewDataFetched,
    required this.messageWidth,
  }) : super(key: key);

  @override
  ConsumerState<TextMessageBuilder> createState() =>
      _TextMessageBuilderConsumerState();
}

class _TextMessageBuilderConsumerState
    extends ConsumerState<TextMessageBuilder> {
  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(clientProvider)!.userId().toString();
    String msgType = '';
    if (widget.message.metadata!.containsKey('msgType')) {
      msgType = widget.message.metadata?['msgType'];
    }
    final bool isNotice =
        (msgType == 'm.notice' || msgType == 'm.server_notice');
    //remove mx-reply tags.
    String parsedString = simplifyBody(widget.message.text);
    bool enlargeEmoji = false;
    final urlRegexp = RegExp(
      r'https://matrix\.to/#/@[A-Za-z0-9]+:[A-Za-z0-9]+\.[A-Za-z0-9]+',
      caseSensitive: false,
    );
    if (widget.message.metadata!.containsKey('enlargeEmoji')) {
      enlargeEmoji = widget.message.metadata!['enlargeEmoji'];
    }

    //will return empty if link is other than mention
    final matches = urlRegexp.allMatches(parsedString);
    if (matches.isEmpty) {
      return LinkPreview(
        metadataTitleStyle: myId == widget.message.author.id
            ? const ActerChatTheme().sentMessageLinkTitleTextStyle
            : const ActerChatTheme().receivedMessageLinkTitleTextStyle,
        metadataTextStyle: myId == widget.message.author.id
            ? const ActerChatTheme().sentMessageLinkDescriptionTextStyle
            : const ActerChatTheme().receivedMessageLinkDescriptionTextStyle,
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
        textWidget: _TextWidget(
          message: widget.message,
          enlargeEmoji:
              widget.message.metadata!['enlargeEmoji'] ?? enlargeEmoji,
          isNotice: isNotice,
        ),
        width: widget.messageWidth.toDouble(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      );
    }
    return _TextWidget(
      message: widget.message,
      enlargeEmoji: enlargeEmoji,
      isNotice: isNotice,
    );
  }

  void _onPreviewDataFetched(types.PreviewData previewData) {
    if (widget.message.previewData == null) {
      final chatRoomState = ref.watch(chatRoomProvider.notifier);
      chatRoomState.handlePreviewDataFetched.call(widget.message, previewData);
    }
  }
}

class _TextWidget extends ConsumerWidget {
  final types.TextMessage message;
  final bool enlargeEmoji;
  final bool isNotice;

  const _TextWidget({
    required this.message,
    required this.enlargeEmoji,
    required this.isNotice,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(clientProvider)!.userId().toString();
    final emojiTextStyle = myId == message.author.id
        ? const ActerChatTheme().sentEmojiMessageTextStyle
        : const ActerChatTheme().receivedEmojiMessageTextStyle;
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
              defaultTextStyle: Theme.of(context).textTheme.bodySmall,
            ),
    );
  }
}
