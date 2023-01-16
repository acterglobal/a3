import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:beamer/beamer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:effektio/common/store/themes/ChatTheme.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/chat_list_controller.dart';
import 'package:effektio/controllers/chat_room_controller.dart';
import 'package:effektio/models/ChatModel.dart';
import 'package:effektio/models/ChatProfileModel.dart';
import 'package:effektio/widgets/AppCommon.dart';
import 'package:effektio/widgets/ChatBubbleBuilder.dart';
import 'package:effektio/widgets/CustomAvatar.dart';
import 'package:effektio/widgets/CustomChatInput.dart';
import 'package:effektio/widgets/EmptyHistoryPlaceholder.dart';
import 'package:effektio/widgets/TextMessageBuilder.dart';
import 'package:effektio/widgets/TypeIndicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:string_validator/string_validator.dart';
import 'package:themed/themed.dart';

class ChatScreen extends StatefulWidget {
  final ChatModel chatModel;

  const ChatScreen({
    Key? key,
    required this.chatModel,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  ChatRoomController roomController = Get.find<ChatRoomController>();
  ChatListController listController = Get.find<ChatListController>();

  @override
  void initState() {
    super.initState();
    roomController.setCurrentRoom(widget.chatModel.room);
  }

  @override
  void dispose() {
    roomController.setCurrentRoom(null);

    super.dispose();
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
                  onTap: () => roomController.handleImageSelection(context),
                  child: Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: SvgPicture.asset('assets/images/camera.svg'),
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
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: SvgPicture.asset('assets/images/document.svg'),
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

  Widget avatarBuilder(String userId) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: SizedBox(
        height: 28,
        width: 28,
        child: CustomAvatar(
          uniqueKey: userId,
          avatar: roomController.getUserAvatar(userId),
          displayName: roomController.getUserName(userId),
          radius: 15,
          isGroup: false,
          cacheHeight: 120,
          cacheWidth: 120,
          stringName: simplifyUserId(userId)!,
        ),
      ),
    );
  }

  Widget customBottomWidget(BuildContext context) {
    return GetBuilder<ChatRoomController>(
      id: 'emoji-reaction',
      builder: (ChatRoomController controller) {
        if (!controller.isEmojiContainerVisible) {
          return CustomChatInput(
            isChatScreen: true,
            roomName: widget.chatModel.roomName ?? AppLocalizations.of(context)!.noName,
            onButtonPressed: () => onSendButtonPressed(controller),
          );
        }
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          color: AppCommonTheme.backgroundColorLight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: () {
                  controller.isEmojiContainerVisible = false;
                  controller.showReplyView = true;
                  controller.update(['emoji-reaction', 'chat-input']);
                },
                child: const Text(
                  'Reply',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  if (controller.isAuthor()) {
                    // redact message call
                    await roomController
                        .redactRoomMessage(roomController.repliedToMessage!.id);
                    roomController.toggleEmojiContainer();
                  } else {
                    showDialog(
                      context: context,
                      builder: (BuildContext ctx) {
                        return Dialog(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            height: 280,
                            decoration: const BoxDecoration(
                              color: AppCommonTheme.backgroundColorLight,
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
                                          Beamer.of(context).beamBack();
                                        },
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Report This Message',
                                    style: AppCommonTheme.appBarTitleStyle,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "You can report this message to Effektio if you think that it goes against our community guidelines. We won't notify the account that you submitted this report",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppCommonTheme.dividerColor,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      showNotYetImplementedMsg(
                                        ctx,
                                        'Report feature not yet implemented',
                                      );
                                      controller.update(['emoji-reaction']);
                                      Beamer.of(context).beamBack();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          color: AppCommonTheme.primaryColor,
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
                  controller.isAuthor() ? 'Unsend' : 'Report',
                  style: TextStyle(
                    color: controller.isAuthor() ? Colors.white : Colors.red,
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
      onPreviewDataFetched: roomController.handlePreviewDataFetched,
      messageWidth: messageWidth,
      controller: roomController,
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
            errorBuilder:
                (BuildContext context, Object url, StackTrace? error) {
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
                          color: AppCommonTheme.primaryColor,
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
              color: AppCommonTheme.primaryColor,
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

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        return Scaffold(
          resizeToAvoidBottomInset: orientation == Orientation.portrait,
          appBar: AppBar(
            backgroundColor: AppCommonTheme.backgroundColor,
            elevation: 1,
            centerTitle: true,
            toolbarHeight: 70,
            leading: IconButton(
              onPressed: () => Beamer.of(context).beamBack(),
              icon: SvgPicture.asset(
                'assets/images/back_button.svg',
                color: AppCommonTheme.svgIconColor,
              ),
            ),
            title: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GetBuilder<ChatRoomController>(
                  id: 'room-profile',
                  builder: (ChatRoomController controller) {
                    return buildRoomName(context);
                  },
                ),
                const SizedBox(height: 5),
                GetBuilder<ChatRoomController>(
                  id: 'active-members',
                  builder: (ChatRoomController controller) {
                    return buildActiveMembers(context);
                  },
                ),
              ],
            ),
            actions: [
              GetBuilder<ChatRoomController>(
                id: 'room-profile',
                builder: (ChatRoomController controller) {
                  return buildProfileAction();
                },
              ),
            ],
          ),
          body: buildBody(context),
        );
      },
    );
  }

  Widget buildProfileAction() {
    return GestureDetector(
      onTap: () {
        Beamer.of(context).beamToNamed('/chatProfile',data: ChatProfileModel(
          client: widget.chatModel.client,
          room: widget.chatModel.room,
          roomName: widget.chatModel.roomName,
          roomAvatar: widget.chatModel.roomAvatar,
          isGroup: true,
          isAdmin: true,
        ),);
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: SizedBox(
          height: 45,
          width: 45,
          child: FittedBox(
            fit: BoxFit.contain,
            child: CustomAvatar(
              uniqueKey: widget.chatModel.room.getRoomId(),
              avatar: widget.chatModel.roomAvatar,
              displayName: widget.chatModel.roomName,
              radius: 20,
              cacheHeight: 120,
              cacheWidth: 120,
              isGroup: true,
              stringName: simplifyRoomId(widget.chatModel.room.getRoomId())!,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildRoomName(BuildContext context) {
    if (widget.chatModel.roomName == null) {
      return Text(AppLocalizations.of(context)!.loadingName);
    }
    return Text(
      widget.chatModel.roomName!,
      overflow: TextOverflow.clip,
      style: ChatTheme01.chatTitleStyle,
    );
  }

  Widget buildActiveMembers(BuildContext context) {
    if (roomController.activeMembers.isEmpty) {
      return const SizedBox(
        height: 15,
        width: 15,
        child: CircularProgressIndicator(color: AppCommonTheme.primaryColor),
      );
    }
    return Text(
      '${roomController.activeMembers.length} ${AppLocalizations.of(context)!.members}',
      style: ChatTheme01.chatBodyStyle + AppCommonTheme.primaryColor,
    );
  }

  Widget buildBody(BuildContext context) {
    if (roomController.isLoading.isTrue) {
      return const Center(
        child: SizedBox(
          height: 15,
          width: 15,
          child: CircularProgressIndicator(color: AppCommonTheme.primaryColor),
        ),
      );
    }
    int invitedIndex = listController.invitations.indexWhere((x) {
      return x.roomId() == widget.chatModel.room.getRoomId();
    });
    return GetBuilder<ChatRoomController>(
      id: 'Chat',
      builder: (ChatRoomController controller) {
        return Stack(
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
              customStatusBuilder: customStatusBuilder,
              messages: controller.getMessages(),
              typingIndicatorOptions: TypingIndicatorOptions(
                customTypingIndicator: buildTypingIndicator(),
              ),
              onSendPressed: (types.PartialText partialText) {},
              user: types.User(id: widget.chatModel.client.userId().toString()),
              // disable image preview
              disableImageGallery: true,
              //custom avatar builder
              avatarBuilder: avatarBuilder,
              bubbleBuilder: bubbleBuilder,
              imageMessageBuilder: imageMessageBuilder,
              customMessageBuilder: customMessageBuilder,
              showUserAvatars: true,
              onAttachmentPressed: () => handleAttachmentPressed(context),
              onAvatarTap: (types.User user) {
                showNotYetImplementedMsg(
                  context,
                  'Chat Profile view is not implemented yet',
                );
              },
              onPreviewDataFetched: controller.handlePreviewDataFetched,
              onMessageTap: controller.handleMessageTap,
              onEndReached:
                  invitedIndex != -1 ? null : controller.handleEndReached,
              onEndReachedThreshold: 0.75,
              onBackgroundTap: () {
                if (controller.isEmojiContainerVisible) {
                  controller.toggleEmojiContainer();
                  roomController.replyMessageWidget = null;
                  roomController.repliedToMessage = null;
                }
              },
              emptyState: const EmptyHistoryPlaceholder(),
              //Custom Theme class, see lib/common/store/chatTheme.dart
              theme: EffektioChatTheme(
                attachmentButtonIcon:
                    SvgPicture.asset('assets/images/attachment.svg'),
                sendButtonIcon: SvgPicture.asset('assets/images/sendIcon.svg'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildTypingIndicator() {
    return GetBuilder<ChatRoomController>(
      id: 'typing indicator',
      builder: (ChatRoomController controller) {
        return TypeIndicator(
          bubbleAlignment: BubbleRtlAlignment.right,
          showIndicator: controller.typingUsers.isNotEmpty,
          options: TypingIndicatorOptions(
            animationSpeed: const Duration(milliseconds: 800),
            typingUsers: controller.typingUsers,
            typingMode: TypingIndicatorMode.text,
          ),
        );
      },
    );
  }

  void onSendButtonPressed(ChatRoomController controller) async {
    controller.sendButtonDisable();
    String markdownText = controller.mentionKey.currentState!.controller!.text;
    String htmlText = controller.mentionKey.currentState!.controller!.text;
    int messageLength = markdownText.length;
    controller.messageTextMapMarkDown.forEach((key, value) {
      markdownText = markdownText.replaceAll(key, value);
    });
    controller.messageTextMapHtml.forEach((key, value) {
      htmlText = htmlText.replaceAll(key, value);
    });
    await controller.handleSendPressed(
      markdownText,
      htmlText,
      messageLength,
    );
    controller.messageTextMapMarkDown.clear();
    controller.mentionKey.currentState!.controller!.clear();
  }

  void showMoreOptions() {
    showModalBottomSheet(
      backgroundColor: AppCommonTheme.backgroundColorLight,
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
                Icons.link,
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
                Icons.bookmark_border_outlined,
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
                Beamer.of(context).beamBack();
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

  Widget bubbleBuilder(
    Widget child, {
    required types.Message message,
    required bool nextMessageInGroup,
  }) {
    return GetBuilder<ChatRoomController>(
      id: 'chat-bubble',
      builder: (context) {
        return ChatBubbleBuilder(
          userId: widget.chatModel.client.userId().toString(),
          child: child,
          message: message,
          nextMessageInGroup: nextMessageInGroup,
          enlargeEmoji: message.metadata!['enlargeEmoji'] ?? false,
        );
      },
    );
  }

  Widget customStatusBuilder(
    types.Message message, {
    required BuildContext context,
  }) {
    if (message.status == types.Status.delivered) {
      return SvgPicture.asset('assets/images/deliveredIcon.svg');
    } else if (message.status == types.Status.seen) {
      return SvgPicture.asset('assets/images/seenIcon.svg');
    } else if (message.status == types.Status.sending) {
      return const Center(
        child: SizedBox(
          height: 10,
          width: 10,
          child: CircularProgressIndicator(
            backgroundColor: Colors.transparent,
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppCommonTheme.primaryColor,
            ),
          ),
        ),
      );
    } else {
      return SvgPicture.asset(
        'assets/images/sentIcon.svg',
        width: 12,
        height: 12,
      );
    }
  }

  Widget customMessageBuilder(
    types.CustomMessage customMessage, {
    required int messageWidth,
  }) {
    if (customMessage.metadata?['itemContentType'] == 'UnableToDecrypt') {
      String text = 'Failed to decrypt message. Re-request session keys.';
      return Container(
        width: sqrt(text.length) * 38.5,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 57),
        child: Text(text, style: ChatTheme01.chatReplyTextStyle),
      );
    }
    if (customMessage.metadata?['itemContentType'] == 'RedactedMessage') {
      String text = '***This message has been deleted.***';
      return Container(
        width: sqrt(text.length) * 38.5,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 57),
        child: Text(text, style: ChatTheme01.chatReplyTextStyle),
      );
    }
    if (customMessage.metadata?['itemContentType'] ==
        'FailedToParseMessageLike') {
      String text = 'FailedToParseMessageLike';
      return Container(
        width: sqrt(text.length) * 38.5,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 57),
        child: Text(text, style: ChatTheme01.chatReplyTextStyle),
      );
    }
    if (customMessage.metadata?['itemContentType'] == 'FailedToParseState') {
      String text = 'FailedToParseState';
      return Container(
        width: sqrt(text.length) * 38.5,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 57),
        child: Text(text, style: ChatTheme01.chatReplyTextStyle),
      );
    }
    return const SizedBox();
  }
}
