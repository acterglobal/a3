import 'package:acter/common/themes/acter_theme.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/utils.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/member/dialogs/show_member_info_drawer.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class TextMessageBuilder extends ConsumerStatefulWidget {
  final Convo convo;
  final types.TextMessage message;
  final int messageWidth;
  final bool isReply;

  const TextMessageBuilder({
    super.key,
    required this.convo,
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
    final client = ref.watch(alwaysClientProvider);
    final userId = client.userId().toString();
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
    final authorId = widget.message.author.id;

    //remove mx-reply tags.
    String parsedString = simplifyBody(widget.message.text);
    final urlRegexp = RegExp(
      r'https://matrix\.to/#/[@!#][A-Za-z0-9\-]+:[A-Za-z0-9\-]+\.[A-Za-z0-9\-]+',
      caseSensitive: false,
    );
    final matches = urlRegexp.allMatches(parsedString);
    //will return empty if link is other than mention
    if (matches.isEmpty) {
      return LinkPreview(
        metadataTitleStyle: userId == authorId
            ? Theme.of(context).chatTheme.sentMessageLinkTitleTextStyle
            : Theme.of(context).chatTheme.receivedMessageLinkTitleTextStyle,
        metadataTextStyle: userId == authorId
            ? Theme.of(context).chatTheme.sentMessageLinkDescriptionTextStyle
            : Theme.of(context)
                .chatTheme
                .receivedMessageLinkDescriptionTextStyle,
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
          wasEdited: wasEdited,
          roomId: widget.convo.getRoomIdStr(),
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
        wasEdited: wasEdited,
        roomId: widget.convo.getRoomIdStr(),
      ),
    );
  }

  void onPreviewDataFetched(types.PreviewData previewData) {
    final chatRoomState = ref.read(chatStateProvider(widget.convo).notifier);
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
        ConstrainedBox(
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
                  onLinkTap: (url) => onLinkTap(url, context, ref),
                  onPillTap: (id) => onPillTap(context, id),
                  backgroundColor: Colors.transparent,
                  data: message.text,
                  shrinkToFit: true,
                  defaultTextStyle:
                      Theme.of(context).textTheme.bodySmall!.copyWith(
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

  Future<void> onPillTap(BuildContext context, String identifier) async {
    if (identifier.isEmpty) return;
    final userId = extractUserIdFromUri(identifier);
    if (userId != null) {
      return await showMemberInfoDrawer(
        context: context,
        roomId: roomId,
        memberId: userId,
        // isShowActions: false,
      );
    }
  }

  Future<void> onLinkTap(Uri uri, BuildContext context, WidgetRef ref) async {
    final roomId = getRoomIdFromLink(uri);

    ///If link is type of matrix room link
    if (roomId != null) {
      await navigateToRoomOrAskToJoin(context, ref, roomId);
    }

    ///If link is other than matrix room link
    ///Then open it on browser
    else {
      await openLink(uri.toString(), context);
    }
  }
}
