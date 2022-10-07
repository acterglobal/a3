import 'dart:io';
import 'dart:math';

import 'package:cached_memory_image/cached_memory_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:effektio/common/store/MockData.dart';
import 'package:effektio/common/store/themes/ChatTheme.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/chat_list_controller.dart';
import 'package:effektio/controllers/chat_room_controller.dart';
import 'package:effektio/screens/HomeScreens/chat/ChatProfile.dart';
import 'package:effektio/widgets/AppCommon.dart';
import 'package:effektio/widgets/CustomAvatar.dart';
import 'package:effektio/widgets/CustomChatInput.dart';
import 'package:effektio/widgets/EmptyMessagesPlaceholder.dart';
import 'package:effektio/widgets/InviteInfoWidget.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show Client, Conversation, FfiBufferUint8, FfiListMember, Member;
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
  final String? user;
  final Client client;
  final List<types.User> typingUsers;
  const ChatScreen({
    Key? key,
    required this.room,
    required this.user,
    required this.client,
    required this.typingUsers,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late types.User _user;
  String roomName = '';
  bool roomState = false;
  final Random random = Random();
  ChatRoomController chatRoomController = Get.put(ChatRoomController());
  ChatListController chatListController = Get.find<ChatListController>();

  @override
  void initState() {
    super.initState();
    _user = types.User(id: widget.user!);

    roomState = random.nextBool();
    chatRoomController.init(widget.room, _user);
    chatListController.setCurrentRoomId(widget.room.getRoomId());
  }

  @override
  void dispose() {
    super.dispose();
    chatListController.setCurrentRoomId(null);
    Get.delete<ChatRoomController>();
  }

  void _handleAttachmentPressed(BuildContext context) {
    showModalBottomSheet<void>(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: SizedBox(
            height: 124,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                GestureDetector(
                  onTap: () => chatRoomController.handleImageSelection(context),
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
                  onTap: () => chatRoomController.handleFileSelection(context),
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

  Future<FfiBufferUint8> _userAvatar(String userId) async {
    Member member = await widget.room.getMember(userId);
    return member.avatar();
  }

  Widget _avatarBuilder(String userId) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: SizedBox(
        height: 28,
        width: 28,
        child: CustomAvatar(
          avatar: _userAvatar(userId),
          displayName: null,
          radius: 15,
          isGroup: false,
          stringName: getNameFromId(userId) ?? '',
        ),
      ),
    );
  }

  Widget _imageMessageBuilder(
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
      } else {
        return CachedMemoryImage(
          uniqueKey: UniqueKey().toString(),
          bytes: kTransparentImage,
          width: messageWidth.toDouble(),
        );
      }
    } else if (isURL(imageMessage.uri)) {
      // remote url
      return CachedNetworkImage(
        imageUrl: imageMessage.uri,
        width: messageWidth.toDouble(),
      );
    } else {
      // local path
      // the image that just sent is displayed from local not remote
      return Image.file(
        File(imageMessage.uri),
        width: messageWidth.toDouble(),
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
              onPressed: () {
                Navigator.pop(context);
              },
              icon: SvgPicture.asset(
                'assets/images/back_button.svg',
                color: AppCommonTheme.svgIconColor,
              ),
            ),
            title: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                FutureBuilder<String>(
                  future: widget.room
                      .displayName()
                      .then((value) => roomName = value),
                  builder: (
                    BuildContext context,
                    AsyncSnapshot<String> snapshot,
                  ) {
                    if (snapshot.hasData) {
                      return Text(
                        snapshot.requireData,
                        overflow: TextOverflow.clip,
                        style: ChatTheme01.chatTitleStyle,
                      );
                    } else {
                      return Text(AppLocalizations.of(context)!.loadingName);
                    }
                  },
                ),
                const SizedBox(height: 5),
                FutureBuilder<FfiListMember>(
                  future: widget.room.activeMembers(),
                  builder: (
                    BuildContext context,
                    AsyncSnapshot<FfiListMember> snapshot,
                  ) {
                    if (snapshot.hasData) {
                      return Text(
                        '${snapshot.requireData.length} ${AppLocalizations.of(context)!.members}',
                        style: ChatTheme01.chatBodyStyle +
                            AppCommonTheme.primaryColor,
                      );
                    } else {
                      return const SizedBox(
                        height: 15,
                        width: 15,
                        child: CircularProgressIndicator(
                          color: AppCommonTheme.primaryColor,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            actions: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatProfileScreen(
                        room: widget.room,
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
                        avatar: widget.room.avatar(),
                        displayName: widget.room.displayName(),
                        radius: 20,
                        isGroup: true,
                        stringName: '',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Obx(
            () => SafeArea(
              bottom: false,
              child: _buildBody(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    if (chatRoomController.isLoading.isTrue) {
      return const Center(
        child: SizedBox(
          height: 15,
          width: 15,
          child: CircularProgressIndicator(
            color: AppCommonTheme.primaryColor,
          ),
        ),
      );
    }
    return GetBuilder<ChatRoomController>(
      id: 'Chat',
      builder: (ChatRoomController controller) {
        return Stack(
          children: [
            Chat(
              customBottomWidget: CustomChatInput(
                isChatScreen: true,
                roomName: roomName,
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
              messages: chatRoomController.messages,
              inputOptions: InputOptions(
                sendButtonVisibilityMode: roomState
                    ? SendButtonVisibilityMode.hidden
                    : SendButtonVisibilityMode.editing,
              ),
              typingIndicatorOptions: TypingIndicatorOptions(
                typingUsers: chatListController.typingUsers,
                typingMode: TypingIndicatorMode.text,
              ),
              onSendPressed: (_) {},
              user: _user,
              disableImageGallery: roomState ? true : false,
              //custom avatar builder
              avatarBuilder: _avatarBuilder,
              imageMessageBuilder: _imageMessageBuilder,
              showUserAvatars: true,
              onAttachmentPressed: () => _handleAttachmentPressed(context),
              onPreviewDataFetched: controller.handlePreviewDataFetched,
              onMessageTap: controller.handleMessageTap,
              onEndReached: roomState ? null : controller.handleEndReached,
              onEndReachedThreshold: 0.75,
              emptyState: const EmptyPlaceholder(),
              //Custom Theme class, see lib/common/store/chatTheme.dart
              theme: EffektioChatTheme(
                attachmentButtonIcon:
                    SvgPicture.asset('assets/images/attachment.svg'),
                sendButtonIcon: SvgPicture.asset('assets/images/sendIcon.svg'),
                seenIcon: SvgPicture.asset('assets/images/seenIcon.svg'),
                deliveredIcon: SvgPicture.asset('assets/images/sentIcon.svg'),
              ),
            ),
            roomState
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        alignment: Alignment.topLeft,
                        padding: const EdgeInsets.fromLTRB(10, 10, 0, 20),
                        color: AppCommonTheme.backgroundColor,
                        height: constraints.maxHeight * 0.25,
                        width: double.infinity,
                        child: Text(
                          AppLocalizations.of(context)!.invitationText1,
                          style: AppCommonTheme.appBarTitleStyle
                              .copyWith(fontSize: 14),
                        ),
                      );
                    },
                  )
                : const SizedBox(),
            roomState
                ? Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: InviteInfoWidget(
                      avatarColor: Colors.white,
                      inviter: inviters[random.nextInt(inviters.length)],
                      groupName: roomName,
                    ),
                  )
                : const SizedBox(),
          ],
        );
      },
    );
  }
}
