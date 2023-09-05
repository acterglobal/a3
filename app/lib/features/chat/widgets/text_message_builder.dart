import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/themes/chat_theme.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TextMessageBuilder extends ConsumerStatefulWidget {
  final Convo convo;
  final types.TextMessage message;
  final int messageWidth;
  final bool isReply;

  const TextMessageBuilder({
    Key? key,
    required this.convo,
    required this.message,
    this.isReply = false,
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
    final client = ref.watch(clientProvider)!;
    final userId = client.userId().toString();
    String msgType = '';
    final metadata = widget.message.metadata;
    if (metadata != null && metadata.containsKey('msgType')) {
      msgType = metadata['msgType'];
    }
    final bool isNotice =
        (msgType == 'm.notice' || msgType == 'm.server_notice');
    bool enlargeEmoji = false;
    if (metadata != null && metadata.containsKey('enlargeEmoji')) {
      enlargeEmoji = metadata['enlargeEmoji'];
    }
    final authorId = widget.message.author.id;

    //remove mx-reply tags.
    String parsedString = simplifyBody(widget.message.text);
    final urlRegexp = RegExp(
      r'https://matrix\.to/#/@[A-Za-z0-9]+:[A-Za-z0-9]+\.[A-Za-z0-9]+',
      caseSensitive: false,
    );
    final matches = urlRegexp.allMatches(parsedString);
    //will return empty if link is other than mention
    if (matches.isEmpty) {
      return LinkPreview(
        metadataTitleStyle: userId == authorId
            ? const ActerChatTheme().sentMessageLinkTitleTextStyle
            : const ActerChatTheme().receivedMessageLinkTitleTextStyle,
        metadataTextStyle: userId == authorId
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
        onPreviewDataFetched: onPreviewDataFetched,
        textWidget: _TextWidget(
          message: widget.message,
          messageWidth: widget.messageWidth,
          enlargeEmoji: enlargeEmoji,
          isNotice: isNotice,
          isReply: widget.isReply,
        ),
        width: widget.messageWidth.toDouble(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(18),
      child: _TextWidget(
        message: widget.message,
        messageWidth: widget.messageWidth,
        enlargeEmoji: enlargeEmoji,
        isNotice: isNotice,
        isReply: widget.isReply,
      ),
    );
  }

  void onPreviewDataFetched(types.PreviewData previewData) {
    if (widget.message.previewData == null) {
      handlePreviewDataFetched(widget.message, previewData);
    }
  }

  // preview message link
  void handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final messages = ref.read(chatStateProvider(widget.convo)).messages;
    final index = messages.indexWhere((x) => x.id == message.id);
    if (index != -1) {
      final updatedMessage = (messages[index] as types.TextMessage).copyWith(
        previewData: previewData,
      );
      WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
        final messagesNotifier =
            ref.read(chatStateProvider(widget.convo).notifier);
        messagesNotifier.replaceMessage(index, updatedMessage);
      });
    }
  }
}

class _TextWidget extends ConsumerWidget {
  final types.TextMessage message;
  final int messageWidth;
  final bool enlargeEmoji;
  final bool isNotice;
  final bool isReply;

  const _TextWidget({
    required this.message,
    required this.messageWidth,
    required this.enlargeEmoji,
    required this.isNotice,
    required this.isReply,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(clientProvider)!;
    final emojiTextStyle = client.userId().toString() == message.author.id
        ? const ActerChatTheme().sentEmojiMessageTextStyle
        : const ActerChatTheme().receivedEmojiMessageTextStyle;
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: messageWidth.toDouble()),
      child: enlargeEmoji
          ? Text(
              message.text,
              style: emojiTextStyle.copyWith(
                overflow: isReply ? TextOverflow.ellipsis : null,
                fontFamily: emojiFont,
              ),
              maxLines: isReply ? 3 : null,
            )
          : Html(
              data: message.text,
              shrinkToFit: true,
              defaultTextStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
                    overflow: isReply ? TextOverflow.ellipsis : null,
                    color: isNotice
                        ? Theme.of(context)
                            .colorScheme
                            .neutral5
                            .withOpacity(0.5)
                        : null,
                  ),
              maxLines: isReply ? 3 : null,
            ),
    );
  }
}
