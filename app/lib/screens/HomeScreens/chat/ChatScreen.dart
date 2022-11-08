import 'dart:io';
import 'dart:math';

import 'package:bubble/bubble.dart';
import 'package:cached_memory_image/cached_memory_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:effektio/common/constants.dart';
import 'package:effektio/common/store/themes/ChatTheme.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/chat_list_controller.dart';
import 'package:effektio/controllers/chat_room_controller.dart';
import 'package:effektio/screens/HomeScreens/chat/ChatProfile.dart';
import 'package:effektio/widgets/AppCommon.dart';
import 'package:effektio/widgets/CustomAvatar.dart';
import 'package:effektio/widgets/CustomChatInput.dart';
import 'package:effektio/widgets/EmojiReactionListItem.dart';
import 'package:effektio/widgets/EmptyHistoryPlaceholder.dart';
import 'package:effektio/widgets/TypeIndicator.dart';
import 'package:effektio/widgets/emoji_row.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show Conversation, FfiBufferUint8;
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:string_validator/string_validator.dart';
import 'package:themed/themed.dart';
import 'package:transparent_image/transparent_image.dart';

class ChatScreen extends StatefulWidget {
  final Future<FfiBufferUint8>? roomAvatar;
  final String? roomName;
  final Conversation room;
  final String userId;

  const ChatScreen({
    Key? key,
    required this.room,
    required this.userId,
    this.roomAvatar,
    this.roomName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with SingleTickerProviderStateMixin {
  ChatRoomController roomController = Get.find<ChatRoomController>();
  ChatListController listController = Get.find<ChatListController>();
  String id = '';
  String authId = '';
  String? currentid;
  late MessageType messagetype;
  bool isEmojiContainerVisible = false;
  static var messageIndex = 0;
  late final tabBarController = TabController(length: 3, vsync: this);
  @override
  void initState() {
    super.initState();

    roomController.setCurrentRoom(widget.room);
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
    if (imageMessage.uri.isEmpty) {
      // binary data
      if (imageMessage.metadata?.containsKey('binary') ?? false) {
        return CachedMemoryImage(
          uniqueKey: imageMessage.id,
          bytes: imageMessage.metadata?['binary'],
          width: messageWidth.toDouble(),
          placeholder: const CircularProgressIndicator(
            color: AppCommonTheme.primaryColor,
          ),
        );
      }
      return CachedMemoryImage(
        uniqueKey: imageMessage.id,
        bytes: kTransparentImage,
        width: messageWidth.toDouble(),
      );
    }
    if (isURL(imageMessage.uri)) {
      // remote url
      return CachedNetworkImage(
        imageUrl: imageMessage.uri,
        width: messageWidth.toDouble(),
        errorWidget: (context, url, error) => const Text(
          'Could not load image',
        ),
      );
    }
    // local path
    // the image that just sent is displayed from local not remote
    return Image.file(
      File(imageMessage.uri),
      width: messageWidth.toDouble(),
      errorBuilder: (context, error, stackTrace) => const Text(
        'Could not load image',
      ),
    );
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
              child: buildBody(context),
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
              user: types.User(id: widget.userId),
              // if invited, disable image gallery
              disableImageGallery: invitedIndex != -1,
              //custom avatar builder
              avatarBuilder: avatarBuilder,
              bubbleBuilder: bubbleBuilder,
              imageMessageBuilder: imageMessageBuilder,
              showUserAvatars: true,
              onAttachmentPressed: () => handleAttachmentPressed(context),
              onPreviewDataFetched: controller.handlePreviewDataFetched,
              onMessageTap: controller.handleMessageTap,
              onEndReached:
                  invitedIndex != -1 ? null : controller.handleEndReached,
              onEndReachedThreshold: 0.75,
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
    controller.sendButtonUpdate();
  }

  Widget bubbleBuilder(
    Widget child, {
    required types.Message message,
    nextMessageInGroup,
  }) {
    for (var element in roomController.messages) {
      id = element.id;
      authId = widget.userId;
      messagetype = element.type;
    }

    return GestureDetector(
      child: Column(
        children: [
          const SizedBox(height: 6),
          Stack(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    isEmojiContainerVisible = false;
                  });
                },
                child: SizedBox(
                  child: Column(
                    crossAxisAlignment: authId != message.author.id
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.end,
                    children: [
                      Visibility(
                        visible:
                            currentid == message.id && isEmojiContainerVisible
                                ? true
                                : false,
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          margin: authId != message.author.id
                              ? const EdgeInsets.only(bottom: 8.0, left: 8.0)
                              : const EdgeInsets.only(bottom: 8.0, right: 8.0),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(30.0),
                            ),
                            color: AppCommonTheme.backgroundColor,
                            border: Border.all(
                              color: AppCommonTheme.dividerColor,
                              width: 2.0,
                            ),
                          ),
                          child: EmojiRow(
                            onEmojiTap: (String value) {
                              setState(() {
                                isEmojiContainerVisible = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$value tapped'),
                                  backgroundColor: AuthTheme.authSuccess,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      GestureDetector(
                        child: Row(
                          textDirection: authId != message.author.id
                              ? TextDirection.ltr
                              : TextDirection.rtl,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Stack(
                                children: [
                                  Bubble(
                                    child: child,
                                    color: authId != message.author.id ||
                                            messagetype ==
                                                types.MessageType.image
                                        ? AppCommonTheme.backgroundColorLight
                                        : AppCommonTheme.primaryColor,
                                    margin: nextMessageInGroup
                                        ? const BubbleEdges.symmetric(
                                            horizontal: 2,
                                          )
                                        : null,
                                    radius: const Radius.circular(12),
                                    nip: nextMessageInGroup
                                        ? BubbleNip.no
                                        : authId != message.author.id
                                            ? BubbleNip.leftBottom
                                            : BubbleNip.rightBottom,
                                  ),
                                  authId != message.author.id
                                      ? Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            width: 100,
                                            height: 16,
                                            alignment: Alignment.topRight,
                                            child: ListView.separated(
                                              shrinkWrap: true,
                                              scrollDirection: Axis.horizontal,
                                              itemCount: 2,
                                              itemBuilder: (_, index) {
                                                return GestureDetector(
                                                  onTap: () {
                                                    showBottomSheet();
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                      4.0,
                                                    ),
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: AppCommonTheme
                                                          .dividerColor,
                                                      borderRadius:
                                                          BorderRadius.all(
                                                        Radius.circular(8),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: const [
                                                        Text(
                                                          heart,
                                                          style: TextStyle(
                                                            fontSize: 8,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 2.0,
                                                        ),
                                                        Text(
                                                          '+12',
                                                          style: TextStyle(
                                                            fontSize: 8,
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                              separatorBuilder: (
                                                BuildContext context,
                                                int index,
                                              ) {
                                                return const SizedBox(
                                                  width: 4,
                                                );
                                              },
                                            ),
                                          ),
                                        )
                                      : Positioned(
                                          bottom: 0,
                                          left: 0,
                                          child: Container(
                                            width: 100,
                                            height: 16,
                                            alignment: Alignment.topLeft,
                                            child: ListView.separated(
                                              shrinkWrap: true,
                                              scrollDirection: Axis.horizontal,
                                              itemCount: 2,
                                              itemBuilder: (_, index) {
                                                return GestureDetector(
                                                  onTap: () {
                                                    showBottomSheet();
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                      4.0,
                                                    ),
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: AppCommonTheme
                                                          .dividerColor,
                                                      borderRadius:
                                                          BorderRadius.all(
                                                        Radius.circular(8),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      children: const [
                                                        Text(
                                                          faceWithTears,
                                                          style: TextStyle(
                                                            fontSize: 8,
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: 2.0,
                                                        ),
                                                        Text(
                                                          '+12',
                                                          style: TextStyle(
                                                            fontSize: 8,
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                              separatorBuilder: (
                                                BuildContext context,
                                                int index,
                                              ) {
                                                return const SizedBox(
                                                  width: 4,
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onLongPress: () {
                          setState(() {
                            messageIndex = roomController.messages.indexWhere(
                              (element) => element.id == message.id,
                            );

                            currentid =
                                roomController.messages[messageIndex].id;

                            if (currentid == message.id) {
                              isEmojiContainerVisible =
                                  !isEmojiContainerVisible;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
        ],
      ),
      onTap: () {
        if (isEmojiContainerVisible) {
          setState(() {
            isEmojiContainerVisible = false;
          });
        }
      },
    );
  }

  void showBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Scaffold(
              backgroundColor: AppCommonTheme.backgroundColorLight,
              body: Column(
                children: [
                  SizedBox(
                    height: 50,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: TabBar(
                        controller: tabBarController,
                        indicator: const BoxDecoration(
                          color: AppCommonTheme.backgroundColor,
                          borderRadius: BorderRadius.all(Radius.circular(12.0)),
                        ),
                        tabs: const [
                          Tab(
                            text: ('All 15'),
                          ),
                          Tab(
                            text: ('$heart +11'),
                          ),
                          Tab(
                            text: ('$faceWithTears +3'),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TabBarView(
                        controller: tabBarController,
                        children: [
                          buildReactionListing(astonishedFace),
                          buildReactionListing(heart),
                          buildReactionListing(faceWithTears),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget buildReactionListing(String emoji) {
    return Expanded(
      child: ListView.separated(
        itemCount: 10,
        itemBuilder: (_, index) {
          return EmojiReactionListItem(emoji: emoji);
        },
        separatorBuilder: (BuildContext context, int index) {
          return const SizedBox(
            height: 12,
          );
        },
      ),
    );
  }
}
