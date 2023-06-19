import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:acter/features/chat/models/joined_room/joined_room.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/providers/notifiers/chat_messages_notifier.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/chat_theme.dart';
import 'package:acter/features/chat/widgets/bubble_builder.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter/features/chat/widgets/custom_input.dart';
import 'package:acter/features/chat/widgets/empty_history_placeholder.dart';
import 'package:acter/features/chat/widgets/text_message_builder.dart';
import 'package:acter/features/chat/widgets/type_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:string_validator/string_validator.dart';

class RoomPage extends ConsumerStatefulWidget {
  final JoinedRoom room;
  final MemoryImage? roomAvatar;
  const RoomPage({
    Key? key,
    required this.room,
    this.roomAvatar,
  }) : super(key: key);

  @override
  ConsumerState<RoomPage> createState() => _RoomPageConsumerState();
}

class _RoomPageConsumerState extends ConsumerState<RoomPage> {
  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          resizeToAvoidBottomInset: orientation == Orientation.portrait,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            elevation: 1,
            centerTitle: true,
            toolbarHeight: 70,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Atlas.arrow_left),
            ),
            title: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  widget.room.displayName ?? widget.room.id,
                  overflow: TextOverflow.clip,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 5),
                Consumer(
                  builder: (context, ref, child) {
                    final activeMembers = ref
                        .watch(chatRoomProvider.select((e) => e.activeMembers));
                    return activeMembers.isEmpty
                        ? const SizedBox(
                            height: 15,
                            width: 15,
                            child: CircularProgressIndicator(),
                          )
                        : Text(
                            '${activeMembers.length} ${AppLocalizations.of(context)!.members}',
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                  },
                ),
              ],
            ),
            actions: [
              InkWell(
                onTap: () {
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => ProfilePage(
                  //       client: client!,
                  //       room: widget.conversation,
                  //       roomName: widget.name,
                  //       isGroup: true,
                  //       isAdmin: true,
                  //     ),
                  //   ),
                  // );
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ActerAvatar(
                    mode: DisplayMode.User,
                    uniqueId: widget.room.id,
                    displayName: widget.room.displayName ?? widget.room.id,
                    size: widget.roomAvatar != null ? 24 : 44,
                    avatar: widget.roomAvatar,
                  ),
                ),
              ),
            ],
          ),
          body: Consumer(
            builder: ((context, ref, child) {
              final clientId = ref.watch(clientProvider)!;
              var r1 = clientId.userId();
              final String id = r1.toString();
              final room = ref.watch(chatRoomProvider);
              int invitedIndex =
                  ref.watch(invitationListProvider).indexWhere((x) {
                var r1 = x.roomId();
                String r2 = r1.toString();
                return r2 == widget.room.id;
              });
              return room.isLoaded
                  ? Stack(
                      children: [
                        Chat(
                          // customBottomWidget: customBottomWidget(context),
                          textMessageBuilder: textMessageBuilder,
                          l10n: ChatL10nEn(
                            emptyChatPlaceholder: '',
                            attachmentButtonAccessibilityLabel: '',
                            fileButtonAccessibilityLabel: '',
                            inputPlaceholder:
                                AppLocalizations.of(context)!.message,
                            sendButtonAccessibilityLabel: '',
                          ),
                          messages: ref.watch(chatMessagesProvider),
                          typingIndicatorOptions: TypingIndicatorOptions(
                            customTypingIndicator: buildTypingIndicator(),
                          ),
                          onSendPressed: (types.PartialText partialText) {},
                          user: types.User(id: id),
                          // disable image preview
                          disableImageGallery: true,
                          //custom avatar builder
                          // avatarBuilder: avatarBuilder,
                          bubbleBuilder: bubbleBuilder,
                          imageMessageBuilder: imageMessageBuilder,
                          customMessageBuilder: customMessageBuilder,
                          showUserAvatars: true,
                          onAttachmentPressed: () =>
                              handleAttachmentPressed(context),
                          onAvatarTap: (types.User user) {
                            customMsgSnackbar(
                              context,
                              'Chat Profile view is not implemented yet',
                            );
                          },
                          onPreviewDataFetched: ref
                              .read(chatRoomProvider.notifier)
                              .handlePreviewDataFetched,
                          onMessageTap: ref
                              .read(chatRoomProvider.notifier)
                              .handleMessageTap,
                          onEndReached: invitedIndex != -1
                              ? null
                              : ref
                                  .read(chatRoomProvider.notifier)
                                  .handleEndReached,
                          onEndReachedThreshold: 0.75,
                          onBackgroundTap: () {
                            if (ref
                                .read(chatInputProvider)
                                .isEmojiContainerVisible) {
                              ref
                                  .read(chatInputProvider.notifier)
                                  .toggleEmojiContainer();
                              ref
                                  .read(chatRoomProvider.notifier)
                                  .setChatRoomState(
                                    repliedToMessage: null,
                                    replyMessageWidget: const SizedBox.shrink(),
                                  );
                            }
                          },
                          emptyState: const EmptyHistoryPlaceholder(),
                          //Custom Theme class, see lib/common/store/chatTheme.dart
                          theme: const ActerChatTheme(
                            attachmentButtonIcon: Icon(Atlas.plus_circle),
                            sendButtonIcon: Icon(Atlas.paper_airplane),
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: SizedBox(
                        height: 15,
                        width: 15,
                        child: CircularProgressIndicator(),
                      ),
                    );
            }),
          ),
        );
      },
    );
  }

  void onSendButtonPressed() async {
    ref.read(chatInputProvider.notifier).sendButtonDisable();
    String markdownText = ref
        .read(chatInputProvider.notifier)
        .mentionKey
        .currentState!
        .controller!
        .text;
    String htmlText = ref
        .read(chatInputProvider.notifier)
        .mentionKey
        .currentState!
        .controller!
        .text;
    int messageLength = markdownText.length;
    ref.read(chatInputProvider).messageTextMapMarkDown.forEach((key, value) {
      markdownText = markdownText.replaceAll(key, value);
    });
    ref.read(chatInputProvider).messageTextMapHtml.forEach((key, value) {
      htmlText = htmlText.replaceAll(key, value);
    });
    await ref.read(chatRoomProvider.notifier).handleSendPressed(
          markdownText,
          htmlText,
          messageLength,
        );
    ref
        .read(chatInputProvider.notifier)
        .setChatInputState(messageTextMapMarkDown: {});
    ref
        .read(chatInputProvider.notifier)
        .mentionKey
        .currentState!
        .controller!
        .clear();
  }

  void showMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              leading: Icon(
                Atlas.link,
                color: Colors.white,
              ),
              title: Text(
                'Copy',
                style: TextStyle(color: Colors.white),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 22),
              width: MediaQuery.of(context).size.width,
              height: 2,
              color: Colors.grey,
            ),
            const ListTile(
              leading: Icon(
                Atlas.book,
                color: Colors.white,
              ),
              title: Text(
                'Bookmark',
                style: TextStyle(color: Colors.white),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 22),
              width: MediaQuery.of(context).size.width,
              height: 2,
              color: Colors.grey,
            ),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void handleAttachmentPressed(BuildContext context) {
    showModalBottomSheet<void>(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: SizedBox(
            height: 124,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  onTap: () => ref
                      .read(chatRoomProvider.notifier)
                      .handleImageSelection(context),
                  child: Row(
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Atlas.camera),
                      ),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          AppLocalizations.of(context)!.photo,
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => ref
                      .read(chatRoomProvider.notifier)
                      .handleFileSelection(context),
                  child: Row(
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Atlas.document),
                      ),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          AppLocalizations.of(context)!.file,
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget avatarBuilder(String userId) {
  //   return Consumer(
  //     builder: (context, ref, child) {
  //       final chatInputState = ref.watch(chatInputProvider.notifier);
  //       return Padding(
  //         padding: const EdgeInsets.only(right: 10),
  //         child: SizedBox(
  //           height: 28,
  //           width: 28,
  //           child: chatInputState.getUserAvatar(userId) != null
  //               ? ActerAvatar(
  //                   mode: DisplayMode.User,
  //                   uniqueId: userId,
  //                   displayName: chatInputState.getUserName(userId),
  //                   size: 50,
  //                   avatar: MemoryImage(
  //                     chatInputState.getUserAvatar(userId)!,
  //                   ),
  //                 )
  //               : ActerAvatar(
  //                   uniqueId: userId,
  //                   mode: DisplayMode.User,
  //                   displayName: chatInputState.getUserName(userId),
  //                   size: 50,
  //                 ),
  //         ),
  //       );
  //     },
  //   );
  // }

  Widget buildTypingIndicator() {
    return Consumer(
      builder: (builder, ref, child) {
        final typingUsers =
            ref.watch(chatRoomProvider.select((e) => e.typingUsers));
        return TypeIndicator(
          bubbleAlignment: BubbleRtlAlignment.right,
          showIndicator: typingUsers.isNotEmpty,
          options: TypingIndicatorOptions(
            animationSpeed: const Duration(milliseconds: 800),
            typingUsers: typingUsers,
            typingMode: TypingIndicatorMode.name,
          ),
        );
      },
    );
  }

  Widget customBottomWidget(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final chatInputState = ref.watch(chatInputProvider);
        return !chatInputState.isEmojiContainerVisible
            ? CustomChatInput(
                isChatScreen: true,
                roomName: widget.room.displayName ??
                    AppLocalizations.of(context)!.noName,
                onButtonPressed: () => onSendButtonPressed(),
              )
            : Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    GestureDetector(
                      onTap: () => ref
                          .read(chatInputProvider.notifier)
                          .setChatInputState(
                            isEmojiContainerVisible: false,
                            showReplyView: true,
                          ),
                      child: const Text(
                        'Reply',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        if (ref.read(chatInputProvider.notifier).isAuthor()) {
                          // redact message call
                          await ref
                              .read(chatRoomProvider.notifier)
                              .redactRoomMessage(
                                ref.read(chatRoomProvider).repliedToMessage!.id,
                              );
                          ref
                              .read(chatInputProvider.notifier)
                              .toggleEmojiContainer();
                        } else {
                          showDialog(
                            context: context,
                            builder: (BuildContext ctx) {
                              return Dialog(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  height: 280,
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(16),
                                    ),
                                  ),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.pop(ctx);
                                              },
                                              child: const Icon(
                                                Atlas.xmark_circle,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Report This Message',
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          "You can report this message to Acter if you think that it goes against our community guidelines. We won't notify the account that you submitted this report",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            customMsgSnackbar(
                                              ctx,
                                              'Report feature not yet implemented',
                                            );
                                            Navigator.pop(ctx);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  14,
                                                ),
                                              ),
                                              child: const Padding(
                                                padding: EdgeInsets.all(8),
                                                child: Center(
                                                  child: Text(
                                                    'Okay!',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      },
                      child: Text(
                        ref.read(chatInputProvider.notifier).isAuthor()
                            ? 'Unsend'
                            : 'Report',
                        style: TextStyle(
                          color: ref.read(chatInputProvider.notifier).isAuthor()
                              ? Colors.white
                              : Colors.red,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        showMoreOptions();
                      },
                      child: const Text(
                        'More',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
      },
    );
  }

  Widget textMessageBuilder(
    types.TextMessage p1, {
    required int messageWidth,
    required bool showName,
  }) {
    return TextMessageBuilder(
      message: p1,
      onPreviewDataFetched:
          ref.read(chatRoomProvider.notifier).handlePreviewDataFetched,
      messageWidth: messageWidth,
    );
  }

  Widget imageMessageBuilder(
    types.ImageMessage imageMessage, {
    required int messageWidth,
  }) {
    if (imageMessage.metadata?.containsKey('base64') ?? false) {
      if (imageMessage.metadata?['base64'].isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.memory(
            base64Decode(imageMessage.metadata?['base64']),
            errorBuilder: (
              BuildContext context,
              Object url,
              StackTrace? error,
            ) {
              return Text('Could not load image due to $error');
            },
            frameBuilder: (
              BuildContext context,
              Widget child,
              int? frame,
              bool wasSynchronouslyLoaded,
            ) {
              if (wasSynchronouslyLoaded) {
                return child;
              }
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: frame != null
                    ? child
                    : const SizedBox(
                        height: 60,
                        width: 60,
                        child: CircularProgressIndicator(
                          strokeWidth: 6,
                        ),
                      ),
              );
            },
            cacheWidth: 256,
            width: messageWidth.toDouble() / 2,
            fit: BoxFit.cover,
          ),
        );
      } else {
        return ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: const SizedBox(
            height: 60,
            width: 60,
            child: CircularProgressIndicator(
              strokeWidth: 6,
            ),
          ),
        );
      }
    } else if (imageMessage.uri.isNotEmpty && isURL(imageMessage.uri)) {
      // remote url
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: CachedNetworkImage(
          imageUrl: imageMessage.uri,
          width: messageWidth.toDouble(),
          errorWidget: (BuildContext context, Object url, dynamic error) {
            return Text('Could not load image due to $error');
          },
        ),
      );
    }
    // local path
    // the image that just sent is displayed from local not remote
    else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.file(
          File(imageMessage.uri),
          width: messageWidth.toDouble(),
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
          ) {
            return Text('Could not load image due to $error');
          },
        ),
      );
    }
  }

  Widget bubbleBuilder(
    Widget child, {
    required types.Message message,
    required bool nextMessageInGroup,
  }) {
    return BubbleBuilder(
      child: child,
      message: message,
      nextMessageInGroup: nextMessageInGroup,
      enlargeEmoji: message.metadata!['enlargeEmoji'] ?? false,
    );
  }

  Widget customMessageBuilder(
    types.CustomMessage customMessage, {
    required int messageWidth,
  }) {
    if (customMessage.metadata?['itemType'] == 'vitrual') {
      return const SizedBox.shrink();
    }
    // state event
    switch (customMessage.metadata?['eventType']) {
      case 'm.policy.rule.room':
      case 'm.policy.rule.server':
      case 'm.policy.rule.user':
      case 'm.room.aliases':
      case 'm.room.avatar':
      case 'm.room.canonical.alias':
      case 'm.room.create':
      case 'm.room.encryption':
      case 'm.room.guest.access':
      case 'm.room.history.visibility':
      case 'm.room.join.rules':
      case 'm.room.name':
      case 'm.room.pinned.events':
      case 'm.room.power.levels':
      case 'm.room.server.acl':
      case 'm.room.third.party.invite':
      case 'm.room.tombstone':
      case 'm.room.topic':
      case 'm.space.child':
      case 'm.space.parent':
        String? text = customMessage.metadata?['body'];
        return text == null
            ? const SizedBox.shrink()
            : Container(
                width: sqrt(text.length) * 38.5,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 57),
                child: Text(text, style: Theme.of(context).textTheme.bodySmall),
              );
    }

    // message event
    switch (customMessage.metadata?['eventType']) {
      case 'm.call.answer':
      case 'm.call.candidates':
      case 'm.call.hangup':
      case 'm.call.invite':
      case 'm.key.verification.accept':
      case 'm.key.verification.cancel':
      case 'm.key.verification.done':
      case 'm.key.verification.key':
      case 'm.key.verification.mac':
      case 'm.key.verification.ready':
      case 'm.key.verification.start':
        break;
      case 'm.room.member':
        String text = customMessage.metadata?['body'];
        return Container(
          padding: const EdgeInsets.only(left: 8, bottom: 6),
          constraints: const BoxConstraints(minWidth: 57),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      case 'm.room.encrypted':
        String text =
            '***Failed to decrypt message. Re-request session keys.***';
        return Container(
          width: sqrt(text.length) * 38.5,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 57),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      case 'm.room.redaction':
        String text = '***This message has been deleted.***';
        return Container(
          width: sqrt(text.length) * 38.5,
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 57),
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        );
      case 'm.sticker':
        return Container(
          width: customMessage.metadata?['width'],
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 57),
          child: Image.memory(
            base64Decode(customMessage.metadata?['base64']),
            errorBuilder: (
              BuildContext context,
              Object url,
              StackTrace? error,
            ) {
              return Text('Could not load image due to $error');
            },
            frameBuilder: (
              BuildContext context,
              Widget child,
              int? frame,
              bool wasSynchronouslyLoaded,
            ) {
              if (wasSynchronouslyLoaded) {
                return child;
              }
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: frame != null
                    ? child
                    : const SizedBox(
                        height: 60,
                        width: 60,
                        child: CircularProgressIndicator(
                          strokeWidth: 6,
                        ),
                      ),
              );
            },
            cacheWidth: 256,
            width: messageWidth.toDouble() / 2,
            fit: BoxFit.cover,
          ),
        );
    }

    return const SizedBox();
  }
}
