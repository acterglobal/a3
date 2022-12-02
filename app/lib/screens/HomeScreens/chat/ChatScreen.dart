import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:effektio/common/store/themes/ChatTheme.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/chat_list_controller.dart';
import 'package:effektio/controllers/chat_room_controller.dart';
import 'package:effektio/controllers/network_controller.dart';
import 'package:effektio/screens/HomeScreens/chat/ChatProfile.dart';
import 'package:effektio/widgets/AppCommon.dart';
import 'package:effektio/widgets/ChatBubbleBuilder.dart';
import 'package:effektio/widgets/CustomAvatar.dart';
import 'package:effektio/widgets/CustomChatInput.dart';
import 'package:effektio/widgets/EmptyHistoryPlaceholder.dart';
import 'package:effektio/widgets/TypeIndicator.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show Client, Conversation, FfiBufferUint8;
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:string_validator/string_validator.dart';
import 'package:themed/themed.dart';

class ChatScreen extends StatefulWidget {
  final Future<FfiBufferUint8>? roomAvatar;
  final String? roomName;
  final Conversation room;
  final Client client;

  const ChatScreen({
    Key? key,
    required this.room,
    required this.client,
    this.roomAvatar,
    this.roomName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  ChatRoomController roomController = Get.find<ChatRoomController>();
  ChatListController listController = Get.find<ChatListController>();
  final networkController = Get.put(NetworkController());

  @override
  void initState() {
    super.initState();

    if (networkController.connectionType.value != '0') {
      roomController.setCurrentRoom(widget.room);
    }
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

  Widget textMessageBuilder(
    types.TextMessage p1, {
    required int messageWidth,
    required bool showName,
  }) {
    return Container(
      width: sqrt(p1.metadata!['messageLength']) * 38.5,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 57),
      child: Html(
        // ignore: prefer_single_quotes, unnecessary_string_interpolations
        data: """${p1.text}""",
        style: {
          'body': Style(color: Colors.white),
          'a': Style(textDecoration: TextDecoration.none)
        },
      ),
    );
  }

  Widget imageMessageBuilder(
    types.ImageMessage imageMessage, {
    required int messageWidth,
  }) {
    // binary data
    // CachedMemoryImage cannot be used, because uniqueKey not working
    // If uniqueKey not working, it means cache is not working
    // So use Image.memory
    // ToDo: must implement image caching someday
    if (imageMessage.metadata?.containsKey('base64') ?? false) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.memory(
          base64Decode(imageMessage.metadata?['base64']),
          errorBuilder: (BuildContext context, Object url, StackTrace? error) {
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
          cacheWidth: 512,
          width: messageWidth.toDouble(),
          fit: BoxFit.cover,
        ),
      );
    }
    if (isURL(imageMessage.uri)) {
      // remote url
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: CachedNetworkImage(
          imageUrl: imageMessage.uri,
          width: messageWidth.toDouble(),
          errorWidget: (BuildContext context, Object url, dynamic error) {
            return const Text('Could not load image');
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
            return const Text('Could not load image');
          },
        ),
      );
    }
  }

  Widget customMessageBuilder(
    types.CustomMessage customMessage, {
    required int messageWidth,
  }) {
    return const SizedBox();
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
              onPressed: () => Navigator.pop(context),
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
                  builder: (_) {
                    return buildRoomName(context);
                  },
                ),
                const SizedBox(height: 5),
                GetBuilder<ChatRoomController>(
                  id: 'active-members',
                  builder: (_) {
                    return buildActiveMembers(context);
                  },
                ),
              ],
            ),
            actions: [
              GetBuilder<ChatRoomController>(
                id: 'room-profile',
                builder: (_) {
                  return buildProfileAction();
                },
              ),
            ],
          ),
          body: Obx(
            () => SafeArea(
              bottom: false,
              child: networkController.connectionType.value == '0'
                  ? noInternetWidget()
                  : buildBody(context),
            ),
          ),
        );
      },
    );
  }

  Widget buildProfileAction() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatProfileScreen(
              client: widget.client,
              room: widget.room,
              roomName: widget.roomName,
              roomAvatar: widget.roomAvatar,
              isGroup: true,
              isAdmin: true,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: SizedBox(
          height: 45,
          width: 45,
          child: FittedBox(
            fit: BoxFit.contain,
            child: CustomAvatar(
              uniqueKey: widget.room.getRoomId(),
              avatar: widget.roomAvatar,
              displayName: widget.roomName,
              radius: 20,
              cacheHeight: 120,
              cacheWidth: 120,
              isGroup: true,
              stringName: simplifyRoomId(widget.room.getRoomId())!,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildRoomName(BuildContext context) {
    if (widget.roomName == null) {
      return Text(AppLocalizations.of(context)!.loadingName);
    }
    return Text(
      widget.roomName!,
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
      return x.roomId() == widget.room.getRoomId();
    });
    return GetBuilder<ChatRoomController>(
      id: 'Chat',
      builder: (ChatRoomController controller) {
        return Stack(
          children: [
            Chat(
              customBottomWidget: CustomChatInput(
                isChatScreen: true,
                roomName:
                    widget.roomName ?? AppLocalizations.of(context)!.noName,
                onButtonPressed: () => onSendButtonPressed(controller),
              ),
              textMessageBuilder: textMessageBuilder,
              l10n: ChatL10nEn(
                emptyChatPlaceholder: '',
                attachmentButtonAccessibilityLabel: '',
                fileButtonAccessibilityLabel: '',
                inputPlaceholder: AppLocalizations.of(context)!.message,
                sendButtonAccessibilityLabel: '',
              ),
              messages: controller.messages,
              typingIndicatorOptions: TypingIndicatorOptions(
                customTypingIndicator: buildTypingIndicator(),
              ),
              onSendPressed: (_) {},
              user: types.User(id: widget.client.userId().toString()),
              // if invited, disable image gallery
              disableImageGallery: invitedIndex != -1,
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
              onBackgroundTap: () => controller.toggleEmojiContainer(),
              emptyState: const EmptyHistoryPlaceholder(),
              //Custom Theme class, see lib/common/store/chatTheme.dart
              theme: EffektioChatTheme(
                attachmentButtonIcon:
                    SvgPicture.asset('assets/images/attachment.svg'),
                sendButtonIcon: SvgPicture.asset('assets/images/sendIcon.svg'),
                seenIcon: SvgPicture.asset('assets/images/seenIcon.svg'),
                deliveredIcon: SvgPicture.asset('assets/images/sentIcon.svg'),
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

  Widget bubbleBuilder(
    Widget child, {
    required types.Message message,
    required bool nextMessageInGroup,
  }) {
    // reaction exists for only `m.text` event
    if (message is types.TextMessage) {
      return ChatBubbleBuilder(
        userId: widget.client.userId().toString(),
        child: child,
        message: message,
        nextMessageInGroup: nextMessageInGroup,
      );
    }
    return const SizedBox();
  }
}
