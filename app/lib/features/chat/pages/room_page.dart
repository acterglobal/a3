import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/chat_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/chat/controllers/chat_room_controller.dart';
import 'package:acter/features/chat/pages/profile_page.dart';
import 'package:acter/features/chat/widgets/bubble_builder.dart';
import 'package:acter/features/chat/widgets/custom_input.dart';
import 'package:acter/features/chat/widgets/empty_history_placeholder.dart';
import 'package:acter/features/chat/widgets/text_message_builder.dart';
import 'package:acter/features/chat/widgets/type_indicator.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Convo;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:string_validator/string_validator.dart';

class RoomPage extends ConsumerStatefulWidget {
  final Convo convo;

  const RoomPage({
    Key? key,
    required this.convo,
  }) : super(key: key);

  @override
  ConsumerState<RoomPage> createState() => _RoomPageConsumerState();
}

class _RoomPageConsumerState extends ConsumerState<RoomPage> {
  late final ChatRoomController roomController;

  @override
  void initState() {
    super.initState();
    final client = ref.read(clientProvider)!;
    roomController = Get.put(ChatRoomController(client: client));
    roomController.setCurrentRoom(widget.convo);
  }

  @override
  void dispose() {
    roomController.setCurrentRoom(null);
    Get.delete<ChatRoomController>();
    super.dispose();
  }

  void onAttach(BuildContext context) {
    showModalBottomSheet(
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
                  onTap: () => roomController.handleImageSelection(context),
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
                  onTap: () => roomController.handleFileSelection(context),
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

  Widget customBottomWidget(BuildContext context) {
    return GetBuilder<ChatRoomController>(
      id: 'emoji-reaction',
      builder: (ChatRoomController ctlr) {
        if (!ctlr.isEmojiContainerVisible) {
          return Consumer(
            builder: (context, ref, child) {
              final convoProfile =
                  ref.watch(chatProfileDataProvider(widget.convo)).requireValue;
              return CustomChatInput(
                roomController: ctlr,
                isChatScreen: true,
                roomName: convoProfile.displayName ??
                    AppLocalizations.of(context)!.noName,
                onButtonPressed: () async => await onSendButtonPressed(ctlr),
              );
            },
          );
        }
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: () {
                  ctlr.isEmojiContainerVisible = false;
                  ctlr.showReplyView = true;
                  ctlr.update(['emoji-reaction', 'chat-input']);
                },
                child: const Text(
                  'Reply',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  if (ctlr.isAuthor()) {
                    // redact message call
                    await ctlr.redactRoomMessage(ctlr.repliedToMessage!.id);
                    ctlr.toggleEmojiContainer();
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
                                    mainAxisAlignment: MainAxisAlignment.end,
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
                                      ctlr.update(['emoji-reaction']);
                                      Navigator.pop(ctx);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
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
                  ctlr.isAuthor() ? 'Unsend' : 'Report',
                  style: TextStyle(
                    color: ctlr.isAuthor() ? Colors.white : Colors.red,
                  ),
                ),
              ),
              const _MoreButton(),
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
      onPreviewDataFetched: roomController.handlePreviewDataFetched,
      messageWidth: messageWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(clientProvider);
    return OrientationBuilder(
      builder: (context, orientation) => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        resizeToAvoidBottomInset: orientation == Orientation.portrait,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          elevation: 1,
          centerTitle: true,
          toolbarHeight: 70,
          leading: IconButton(
            onPressed: () => context.canPop()
                ? context.pop()
                : context.goNamed(Routes.chat.name),
            icon: const Icon(Atlas.arrow_left),
          ),
          title: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GetBuilder<ChatRoomController>(
                id: 'room-profile',
                builder: (ChatRoomController ctlr) => Consumer(
                  builder: (context, ref, child) {
                    final convoProfile = ref.watch(
                      chatProfileDataProvider(widget.convo),
                    );
                    return convoProfile.when(
                      data: (profile) {
                        if (profile.displayName == null) {
                          return Text(
                            AppLocalizations.of(context)!.loadingName,
                          );
                        }
                        var roomId = widget.convo.getRoomIdStr();
                        return Text(
                          profile.displayName ?? roomId,
                          overflow: TextOverflow.clip,
                          style: Theme.of(context).textTheme.bodyLarge,
                        );
                      },
                      error: (error, stackTrace) => Text(
                        'Error loading profile $error',
                      ),
                      loading: () => const CircularProgressIndicator(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 5),
              GetBuilder<ChatRoomController>(
                id: 'active-members',
                builder: (ChatRoomController ctlr) {
                  if (ctlr.activeMembers.isEmpty) {
                    return const SizedBox(
                      height: 15,
                      width: 15,
                      child: CircularProgressIndicator(),
                    );
                  }
                  int count = ctlr.activeMembers.length;
                  return Text(
                    '$count ${AppLocalizations.of(context)!.members}',
                    style: Theme.of(context).textTheme.bodySmall,
                  );
                },
              ),
            ],
          ),
          actions: [
            GetBuilder<ChatRoomController>(
              id: 'room-profile',
              builder: (ChatRoomController ctlr) {
                String roomId = widget.convo.getRoomId().toString();
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(
                          client: client!,
                          room: widget.convo,
                          isGroup: true,
                          isAdmin: true,
                        ),
                      ),
                    );
                  },
                  child: Consumer(
                    builder: (context, ref, child) {
                      final convoProfile = ref.watch(
                        chatProfileDataProvider(widget.convo),
                      );
                      return convoProfile.when(
                        data: (data) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ActerAvatar(
                            mode: DisplayMode.User,
                            uniqueId: roomId,
                            displayName: data.displayName ?? roomId,
                            avatar: data.getAvatarImage(),
                            size: data.hasAvatar() ? 24 : 45,
                          ),
                        ),
                        error: (error, stackTrace) => Text(
                          'Failed to load avatar due to $error',
                        ),
                        loading: () => const CircularProgressIndicator(),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
        body: Obx(() {
          if (roomController.isLoading.isTrue) {
            return const Center(
              child: SizedBox(
                height: 15,
                width: 15,
                child: CircularProgressIndicator(),
              ),
            );
          }
          return GetBuilder<ChatRoomController>(
            id: 'Chat',
            builder: (ChatRoomController ctlr) => Stack(
              children: [
                Chat(
                  customBottomWidget: customBottomWidget(context),
                  textMessageBuilder: textMessageBuilder,
                  l10n: ChatL10nEn(
                    emptyChatPlaceholder: '',
                    attachmentButtonAccessibilityLabel: '',
                    fileButtonAccessibilityLabel: '',
                    inputPlaceholder: AppLocalizations.of(context)!.message,
                    sendButtonAccessibilityLabel: '',
                  ),
                  messages: ctlr.getMessages(),
                  typingIndicatorOptions: TypingIndicatorOptions(
                    customTypingIndicator: GetBuilder<ChatRoomController>(
                      id: 'typing indicator',
                      builder: (ChatRoomController ctlr) {
                        return TypeIndicator(
                          bubbleAlignment: BubbleRtlAlignment.right,
                          showIndicator: ctlr.typingUsers.isNotEmpty,
                          options: TypingIndicatorOptions(
                            animationSpeed: const Duration(milliseconds: 800),
                            typingUsers: ctlr.typingUsers,
                            typingMode: TypingIndicatorMode.name,
                          ),
                        );
                      },
                    ),
                  ),
                  onSendPressed: (types.PartialText partialText) {},
                  user: types.User(id: client!.userId().toString()),
                  // disable image preview
                  disableImageGallery: true,
                  //custom avatar builder
                  avatarBuilder: (userId) {
                    var profile = ctlr.getUserProfile(userId);
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: SizedBox(
                        height: 28,
                        width: 28,
                        child: ActerAvatar(
                          mode: DisplayMode.User,
                          uniqueId: userId,
                          displayName: profile?.displayName,
                          avatar: profile?.getAvatarImage(),
                          size: 50,
                        ),
                      ),
                    );
                  },
                  bubbleBuilder: (
                    child, {
                    required message,
                    required nextMessageInGroup,
                  }) {
                    return GetBuilder<ChatRoomController>(
                      id: 'chat-bubble',
                      builder: (ChatRoomController ctlr) => BubbleBuilder(
                        userId: client.userId().toString(),
                        child: child,
                        message: message,
                        nextMessageInGroup: nextMessageInGroup,
                        enlargeEmoji:
                            message.metadata!['enlargeEmoji'] ?? false,
                      ),
                    );
                  },
                  imageMessageBuilder: (message, {required messageWidth}) {
                    return _ImageMessage(
                      message: message,
                      messageWidth: messageWidth,
                    );
                  },
                  customMessageBuilder: (message, {required messageWidth}) {
                    return _CustomMessage(
                      message: message,
                      messageWidth: messageWidth,
                    );
                  },
                  showUserAvatars: true,
                  onAttachmentPressed: () => onAttach(context),
                  onAvatarTap: (types.User user) => customMsgSnackbar(
                    context,
                    'Chat Profile view is not implemented yet',
                  ),
                  onPreviewDataFetched: ctlr.handlePreviewDataFetched,
                  onMessageTap: ctlr.handleMessageTap,
                  onEndReached: ctlr.handleEndReached,
                  onEndReachedThreshold: 0.75,
                  onBackgroundTap: () {
                    if (ctlr.isEmojiContainerVisible) {
                      ctlr.toggleEmojiContainer();
                      ctlr.replyMessageWidget = null;
                      ctlr.repliedToMessage = null;
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
            ),
          );
        }),
      ),
    );
  }

  Future<void> onSendButtonPressed(ChatRoomController ctlr) async {
    ctlr.sendButtonDisable();
    String markdownText = ctlr.mentionKey.currentState!.controller!.text;
    String htmlText = ctlr.mentionKey.currentState!.controller!.text;
    int messageLength = markdownText.length;
    ctlr.messageTextMapMarkDown.forEach((key, value) {
      markdownText = markdownText.replaceAll(key, value);
    });
    ctlr.messageTextMapHtml.forEach((key, value) {
      htmlText = htmlText.replaceAll(key, value);
    });
    await ctlr.handleSendPressed(
      markdownText,
      htmlText,
      messageLength,
    );
    ctlr.messageTextMapMarkDown.clear();
    ctlr.mentionKey.currentState!.controller!.clear();
  }
}

class _ImageMessage extends StatelessWidget {
  final types.ImageMessage message;
  final int messageWidth;

  const _ImageMessage({
    Key? key,
    required this.message,
    required this.messageWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (message.metadata?.containsKey('base64') ?? false) {
      if (message.metadata?['base64'].isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.memory(
            base64Decode(message.metadata?['base64']),
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
                        child: CircularProgressIndicator(strokeWidth: 6),
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
            child: CircularProgressIndicator(strokeWidth: 6),
          ),
        );
      }
    } else if (message.uri.isNotEmpty && isURL(message.uri)) {
      // remote url
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: CachedNetworkImage(
          imageUrl: message.uri,
          width: messageWidth.toDouble(),
          errorWidget: (
            BuildContext context,
            Object url,
            dynamic error,
          ) {
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
          File(message.uri),
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
}

class _CustomMessage extends StatelessWidget {
  final types.CustomMessage message;
  final int messageWidth;

  const _CustomMessage({
    Key? key,
    required this.message,
    required this.messageWidth,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // state event
    switch (message.metadata?['eventType']) {
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
        String? text = message.metadata?['body'];
        return text == null
            ? const SizedBox.shrink()
            : Container(
                width: sqrt(text.length) * 38.5,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(minWidth: 57),
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
    }

    // message event
    switch (message.metadata?['eventType']) {
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
        String text = message.metadata?['body'];
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
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      case 'm.sticker':
        return Container(
          width: message.metadata?['width'],
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 57),
          child: Image.memory(
            base64Decode(message.metadata?['base64']),
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
                        child: CircularProgressIndicator(strokeWidth: 6),
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

class _MoreButton extends StatelessWidget {
  const _MoreButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onClick(context),
      child: const Text(
        'More',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  void onClick(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(15),
        ),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              leading: Icon(Atlas.link, color: Colors.white),
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
              leading: Icon(Atlas.book, color: Colors.white),
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
              onTap: () => onCancel(context),
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

  void onCancel(BuildContext context) {
    Navigator.pop(context);
  }
}
