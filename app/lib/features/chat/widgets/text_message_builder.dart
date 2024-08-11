import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/themes/acter_theme.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/utils.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/pill_builder.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_matrix_html/text_parser.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

// removes all matrix custom links
String _cleanMessage(String input) {
  final cleaned = simplifyBody(input).replaceAll(ChatUtils.matrixLinks, '');
  return cleaned;
}

class TextMessageBuilder extends ConsumerStatefulWidget {
  final String roomId;
  final types.TextMessage message;
  final int messageWidth;
  final bool isReply;

  const TextMessageBuilder({
    super.key,
    required this.roomId,
    required this.message,
    this.isReply = false,
    required this.messageWidth,
  });

  @override
  ConsumerState<TextMessageBuilder> createState() =>
      _TextMessageBuilderConsumerState();
}

class _TextMessageBuilderConsumerState
    extends ConsumerState<TextMessageBuilder> {
  @override
  Widget build(BuildContext context) {
    String msgType = '';
    final metadata = widget.message.metadata;
    if (metadata?.containsKey('msgType') == true) {
      msgType = metadata!['msgType'];
    }
    final bool isNotice =
        (msgType == 'm.notice' || msgType == 'm.server_notice');
    bool enlargeEmoji = false;
    if (metadata?.containsKey('enlargeEmoji') == true) {
      enlargeEmoji = metadata!['enlargeEmoji'];
    }
    bool wasEdited = false;
    if (metadata?.containsKey('was_edited') == true) {
      wasEdited = metadata!['was_edited'];
    }
    final isAuthor = widget.message.author.id == ref.watch(myUserIdStrProvider);

    //will return empty if link is other than mention
    return LinkPreview(
      metadataTitleStyle: isAuthor
          ? Theme.of(context).chatTheme.sentMessageLinkTitleTextStyle
          : Theme.of(context).chatTheme.receivedMessageLinkTitleTextStyle,
      metadataTextStyle: isAuthor
          ? Theme.of(context).chatTheme.sentMessageLinkDescriptionTextStyle
          : Theme.of(context).chatTheme.receivedMessageLinkDescriptionTextStyle,
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
      text: _cleanMessage(widget.message.text),
      onPreviewDataFetched: onPreviewDataFetched,
      textWidget: _TextWidget(
        message: widget.message,
        messageWidth: widget.messageWidth,
        enlargeEmoji: enlargeEmoji,
        isNotice: isNotice,
        isReply: widget.isReply,
        wasEdited: wasEdited,
        roomId: widget.roomId,
      ),
      width: widget.messageWidth.toDouble(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  void onPreviewDataFetched(types.PreviewData previewData) {
    final chatRoomState = ref.read(chatStateProvider(widget.roomId).notifier);
    chatRoomState.handlePreviewDataFetched(widget.message, previewData);
  }
}

class _TextWidget extends ConsumerWidget {
  final types.TextMessage message;
  final int messageWidth;
  final bool enlargeEmoji;
  final bool isNotice;
  final bool isReply;
  final bool wasEdited;
  final String roomId;

  const _TextWidget({
    required this.message,
    required this.messageWidth,
    required this.enlargeEmoji,
    required this.isNotice,
    required this.isReply,
    required this.wasEdited,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(alwaysClientProvider);
    final emojiTextStyle = client.userId().toString() == message.author.id
        ? Theme.of(context).chatTheme.sentEmojiMessageTextStyle
        : Theme.of(context).chatTheme.receivedEmojiMessageTextStyle;

    return Column(
      children: [
        enlargeEmoji
            ? Text(
                message.text,
                style: emojiTextStyle.copyWith(
                  overflow: isReply ? TextOverflow.ellipsis : null,
                  fontFamily: emojiFont,
                ),
                maxLines: isReply ? 3 : null,
              )
            : Html(
                onLinkTap: (url) => ChatUtils.onLinkTap(url, context),
                backgroundColor: Colors.transparent,
                renderNewlines: true,
                shrinkToFit: true,
                data: message.text,
                pillBuilder: ({
                  required String identifier,
                  required String url,
                  OnPillTap? onTap,
                }) =>
                    pillBuilder(
                  context: context,
                  roomId: roomId,
                  identifier: identifier,
                  uri: url,
                  onTap: () => ChatUtils.onLinkTap(Uri.parse(url), context),
                ),
                defaultTextStyle:
                    Theme.of(context).textTheme.bodySmall!.copyWith(
                          overflow: isReply ? TextOverflow.ellipsis : null,
                          color: isNotice
                              ? Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5)
                              : null,
                        ),
                maxLines: isReply ? 3 : null,
              ),
        Visibility(
          visible: wasEdited,
          child: Text(
            L10n.of(context).edited,
            style: Theme.of(context)
                .chatTheme
                .emptyChatPlaceholderTextStyle
                .copyWith(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
