import 'dart:io';

import 'package:cached_memory_image/cached_memory_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:effektio/common/store/themes/ChatTheme.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/chat_list_controller.dart';
import 'package:effektio/controllers/chat_room_controller.dart';
import 'package:effektio/screens/HomeScreens/chat/ChatProfile.dart';
import 'package:effektio/widgets/AppCommon.dart';
import 'package:effektio/widgets/CustomAvatar.dart';
import 'package:effektio/widgets/CustomChatInput.dart';
import 'package:effektio/widgets/EmptyHistoryPlaceholder.dart';
import 'package:effektio/widgets/TypeIndicator.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show Conversation, FfiBufferUint8, FfiListMember, UserProfile;
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:string_validator/string_validator.dart';
import 'package:themed/themed.dart';
import 'package:transparent_image/transparent_image.dart';

class ChatScreen extends StatefulWidget {
  final Conversation room;
  final String userId;

  const ChatScreen({
    Key? key,
    required this.room,
    required this.userId,
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
        child: GetBuilder<ChatRoomController>(
          id: 'user-profile-$userId',
          builder: (_) {
            return CustomAvatar(
              avatar: roomController.getUserAvatar(userId),
              displayName: roomController.getUserName(userId),
              radius: 15,
              isGroup: false,
              stringName: simplifyUserId(userId)!,
            );
          },
        ),
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
        uniqueKey: UniqueKey().toString(),
        bytes: kTransparentImage,
        width: messageWidth.toDouble(),
      );
    }
    if (isURL(imageMessage.uri)) {
      // remote url
      return CachedNetworkImage(
        imageUrl: imageMessage.uri,
        width: messageWidth.toDouble(),
      );
    }
    // local path
    // the image that just sent is displayed from local not remote
    return Image.file(
      File(imageMessage.uri),
      width: messageWidth.toDouble(),
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
              roomController: roomController,
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
              avatar: roomController.roomAvatar,
              displayName: roomController.roomName,
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
    if (roomController.roomName == null) {
      return Text(AppLocalizations.of(context)!.loadingName);
    }
    return Text(
      roomController.roomName!,
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
                roomName: roomController.roomName ??
                    AppLocalizations.of(context)!.noName,
                onButtonPressed: () async {
                  await controller.handleSendPressed(
                    controller.textEditingController.text,
                  );
                  controller.textEditingController.clear();
                  controller.sendButtonUpdate();
                },
              ),
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
}
