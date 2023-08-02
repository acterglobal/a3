import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/themes/chat_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/chat/pages/profile_page.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/bubble_builder.dart';
import 'package:acter/features/chat/widgets/custom_input.dart';
import 'package:acter/features/chat/widgets/custom_message_builder.dart';
import 'package:acter/features/chat/widgets/image_message_builder.dart';
import 'package:acter/features/chat/widgets/text_message_builder.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Convo;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ref.watch(chatRoomProvider.notifier).init(widget.convo.getRoomIdStr());
      ref.watch(chatRoomProvider.notifier).fetchUserProfiles();
    });
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

  Widget textMessageBuilder(
    types.TextMessage p1, {
    required int messageWidth,
    required bool showName,
  }) {
    return TextMessageBuilder(
      message: p1,
      onPreviewDataFetched:
          ref.watch(chatRoomProvider.notifier).handlePreviewDataFetched,
      messageWidth: messageWidth,
    );
  }

  Widget imageMessageBuilder(
    types.ImageMessage message, {
    required int messageWidth,
  }) {
    return ImageMessageBuilder(
      message: message,
      messageWidth: messageWidth,
    );
  }

  Widget customMessageBuilder(
    types.CustomMessage message, {
    required int messageWidth,
  }) {
    return CustomMessageBuilder(
      message: message,
      messageWidth: messageWidth,
    );
  }

  Widget bubbleBuilder(
    Widget child, {
    required types.Message message,
    required bool nextMessageInGroup,
  }) {
    return BubbleBuilder(
      userId: ref.watch(clientProvider)!.userId().toString(),
      message: message,
      nextMessageInGroup: nextMessageInGroup,
      enlargeEmoji: message.metadata!['enlargeEmoji'] ?? false,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(clientProvider);
    final chatRoomState = ref.watch(chatRoomProvider);
    ref.listen(messagesProvider, (previous, next) {
      if (next.isNotEmpty) {
        ref.watch(chatRoomProvider.notifier).isLoaded();
      }
    });
    return OrientationBuilder(
      builder: (context, orientation) => Scaffold(
        backgroundColor: Theme.of(context).colorScheme.neutral,
        resizeToAvoidBottomInset: orientation == Orientation.portrait,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.onPrimary,
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
              Consumer(
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
              const SizedBox(height: 5),
              Consumer(
                builder: (context, ref, child) {
                  final activeMembers = ref
                      .watch(chatMembersProvider(widget.convo.getRoomIdStr()));
                  return activeMembers.when(
                    data: (members) {
                      int count = members.length;
                      return Text(
                        '$count ${AppLocalizations.of(context)!.members}',
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    },
                    error: (error, stackTrace) =>
                        Text('Error loading members count $error'),
                    loading: () => const CircularProgressIndicator(),
                  );
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
                    data: (profile) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: profile.hasAvatar()
                          ? ActerAvatar(
                              uniqueId: widget.convo.getRoomIdStr(),
                              mode: DisplayMode.GroupChat,
                              displayName: profile.displayName ??
                                  widget.convo.getRoomIdStr(),
                              avatar: profile.getAvatarImage(),
                              size: 36,
                            )
                          : Container(
                              height: 36,
                              width: 36,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).colorScheme.onSecondary,
                                borderRadius: BorderRadius.circular(6),
                                shape: BoxShape.rectangle,
                              ),
                              child: SvgPicture.asset(
                                'assets/icon/acter.svg',
                              ),
                            ),
                    ),
                    error: (error, stackTrace) => Text(
                      'Failed to load avatar due to $error',
                    ),
                    loading: () => const CircularProgressIndicator(),
                  );
                },
              ),
            ),
          ],
        ),
        body: chatRoomState.when(
          loading: () => const Center(
            child: SizedBox(
              height: 15,
              width: 15,
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e) => Text('Failed to load messages due to $e'),
          loaded: () => Chat(
            customBottomWidget: const CustomChatInput(),
            textMessageBuilder: textMessageBuilder,
            l10n: ChatL10nEn(
              emptyChatPlaceholder: '',
              attachmentButtonAccessibilityLabel: '',
              fileButtonAccessibilityLabel: '',
              inputPlaceholder: AppLocalizations.of(context)!.message,
              sendButtonAccessibilityLabel: '',
            ),
            messages: ref.watch(messagesProvider),
            onSendPressed: (types.PartialText partialText) {},
            user: types.User(id: client!.userId().toString()),
            // disable image preview
            disableImageGallery: true,
            //custom avatar builder
            avatarBuilder: (userId) {
              var profile =
                  ref.watch(chatRoomProvider.notifier).getUserProfile(userId);
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
            bubbleBuilder: bubbleBuilder,
            imageMessageBuilder: imageMessageBuilder,
            customMessageBuilder: customMessageBuilder,
            showUserAvatars: true,
            onAttachmentPressed: () => onAttach(context),
            onAvatarTap: (types.User user) => customMsgSnackbar(
              context,
              'Chat Profile view is not implemented yet',
            ),
            onMessageTap: ref.read(chatRoomProvider.notifier).handleMessageTap,
            onEndReached: ref.read(chatRoomProvider.notifier).handleEndReached,
            onEndReachedThreshold: 0.75,
            onBackgroundTap: () {
              if (ref.watch(
                chatInputProvider.select((ci) => ci.emojiRowVisible),
              )) {
                ref.read(chatRoomProvider.notifier).currentMessageId = null;
                ref.read(chatInputProvider.notifier).emojiRowVisible(false);
              }
            },
            //Custom Theme class, see lib/common/store/chatTheme.dart
            theme: const ActerChatTheme(
              attachmentButtonIcon: Icon(Atlas.plus_circle),
              sendButtonIcon: Icon(Atlas.paper_airplane),
            ),
          ),
        ),
      ),
    );
  }
}
