import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/themes/chat_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/spaces/space_parent_badge.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/bubble_builder.dart';
import 'package:acter/features/chat/widgets/custom_input.dart';
import 'package:acter/features/chat/widgets/custom_message_builder.dart';
import 'package:acter/features/chat/widgets/image_message_builder.dart';
import 'package:acter/features/chat/widgets/text_message_builder.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RoomPage extends ConsumerStatefulWidget {
  const RoomPage({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<RoomPage> createState() => _RoomPageConsumerState();
}

class _RoomPageConsumerState extends ConsumerState<RoomPage> {
  void onAttach(BuildContext context) {
    var roomNotifier = ref.read(chatRoomProvider.notifier);
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
                  onTap: () => roomNotifier.handleImageSelection(context),
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
                  onTap: () => roomNotifier.handleFileSelection(context),
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

  void onBackgroundTap() {
    var emojiRowVisible = ref.read(
      chatInputProvider.select((ci) {
        return ci.emojiRowVisible;
      }),
    );
    var roomNotifier = ref.read(chatRoomProvider.notifier);
    var inputNotifier = ref.read(chatInputProvider.notifier);
    if (emojiRowVisible) {
      roomNotifier.currentMessageId = null;
      inputNotifier.emojiRowVisible(false);
    }
  }

  Widget avatarBuilder(String userId) {
    final memberProfile = ref.watch(memberProfileProvider(userId));
    return memberProfile.when(
      data: (profile) {
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: SizedBox(
            height: 28,
            width: 28,
            child: ActerAvatar(
              mode: DisplayMode.User,
              uniqueId: userId,
              displayName: profile.displayName ?? userId,
              avatar: profile.getAvatarImage(),
            ),
          ),
        );
      },
      error: (e, st) {
        debugPrint('ERROR loading avatar due to $e');
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ActerAvatar(
            uniqueId: userId,
            displayName: userId,
            mode: DisplayMode.User,
            size: 28,
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
    );
  }

  Widget textMessageBuilder(
    types.TextMessage m, {
    required int messageWidth,
    required bool showName,
  }) {
    final roomNotifier = ref.watch(chatRoomProvider.notifier);
    return TextMessageBuilder(
      message: m,
      onPreviewDataFetched: roomNotifier.handlePreviewDataFetched,
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
    final roomNotifier = ref.watch(chatRoomProvider.notifier);
    final convo = ref.watch(currentConvoProvider);
    final convoProfile = ref.watch(chatProfileDataProvider(convo!));
    final activeMembers = ref.watch(chatMembersProvider(convo.getRoomIdStr()));
    ref.listen(messagesProvider, (previous, next) {
      if (next.isNotEmpty) {
        roomNotifier.isLoaded();
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
          title: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              convoProfile.when(
                data: (profile) {
                  var roomId = convo.getRoomIdStr();
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
              ),
              const SizedBox(height: 5),
              activeMembers.when(
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
              ),
            ],
          ),
          actions: [
            GestureDetector(
              onTap: () => context.pushNamed(
                Routes.chatProfile.name,
                pathParameters: {'roomId': convo.getRoomIdStr()},
              ),
              child: convoProfile.when(
                data: (profile) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: SpaceParentBadge(
                    spaceId: convo.getRoomIdStr(),
                    badgeSize: 20,
                    child: ActerAvatar(
                      uniqueId: convo.getRoomIdStr(),
                      mode: DisplayMode.GroupChat,
                      displayName: profile.displayName ?? convo.getRoomIdStr(),
                      avatar: profile.getAvatarImage(),
                      size: 36,
                    ),
                  ),
                ),
                error: (error, stackTrace) => Text(
                  'Failed to load avatar due to $error',
                ),
                loading: () => const CircularProgressIndicator(),
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
            // custom avatar builder
            avatarBuilder: avatarBuilder,
            isLastPage: !ref.watch(paginationProvider),
            bubbleBuilder: bubbleBuilder,
            imageMessageBuilder: imageMessageBuilder,
            customMessageBuilder: customMessageBuilder,
            showUserAvatars: true,
            onAttachmentPressed: () => onAttach(context),
            onMessageLongPress: roomNotifier.handleMessageTap,
            onMessageTap: roomNotifier.handleMessageTap,
            onEndReached: roomNotifier.handleEndReached,
            onEndReachedThreshold: 0.75,
            onBackgroundTap: onBackgroundTap,
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
