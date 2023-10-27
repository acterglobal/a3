import 'dart:io';
import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/themes/chat_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/frost_effect.dart';
import 'package:acter/common/widgets/spaces/space_parent_badge.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/avatar_builder.dart';
import 'package:acter/features/chat/widgets/bubble_builder.dart';
import 'package:acter/features/chat/widgets/custom_input.dart';
import 'package:acter/features/chat/widgets/custom_message_builder.dart';
import 'package:acter/features/chat/widgets/image_message_builder.dart';
import 'package:acter/features/chat/widgets/room_avatar.dart';
import 'package:acter/features/chat/widgets/text_message_builder.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class RoomPage extends ConsumerWidget {
  final String roomId;

  const RoomPage({
    required this.roomId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(chatProvider(roomId)).when(
          data: (convo) => ChatRoom(convo: convo),
          error: (e, s) => Center(child: Text('Loading room failed: $e')),
          loading: () => const Center(child: Text('loading...')),
        );
  }
}

class ChatRoom extends ConsumerStatefulWidget {
  final Convo convo;

  const ChatRoom({
    required this.convo,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<ChatRoom> createState() => _ChatRoomConsumerState();
}

class _ChatRoomConsumerState extends ConsumerState<ChatRoom> {
  void onBackgroundTap() {}

  void showMessageOptions(
    BuildContext context,
    types.Message message,
    String roomId,
  ) async {
    if (message is types.CustomMessage) {
      if (message.metadata!.containsKey('eventType') &&
          message.metadata!['eventType'] == 'm.room.redaction') {
        return;
      }
    }
    final inputNotifier = ref.read(chatInputProvider(roomId).notifier);
    if (ref.read(chatInputProvider(roomId)).showReplyView) {
      inputNotifier.toggleReplyView(false);
      inputNotifier.setReplyWidget(null);
    }
    inputNotifier.setCurrentMessageId(message.id);
    inputNotifier.emojiRowVisible(true);
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(clientProvider);
    final convo = widget.convo;
    final inSideBar = ref.watch(inSideBarProvider);
    final convoProfile = ref.watch(chatProfileDataProvider(convo));
    final activeMembers = ref.watch(chatMembersProvider(convo.getRoomIdStr()));
    final chatState = ref.watch(chatStateProvider(convo));
    final messages = chatState.messages
        .where(
          // filter only items we can show
          (m) => m is! types.UnsupportedMessage,
        )
        .toList()
        .reversed
        .toList();

    final roomId = widget.convo.getRoomIdStr();
    return OrientationBuilder(
      builder: (context, orientation) => Scaffold(
        resizeToAvoidBottomInset: orientation == Orientation.portrait,
        body: CustomScrollView(
          physics: const NeverScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              elevation: 0,
              automaticallyImplyLeading: false,
              centerTitle: true,
              toolbarHeight: 70,
              leading: !inSideBar
                  ? IconButton(
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.goNamed(Routes.chat.name),
                      icon: const Icon(Icons.chevron_left_outlined, size: 28),
                    )
                  : null,
              flexibleSpace: FrostEffect(
                child: Container(
                  color:
                      Theme.of(context).colorScheme.onPrimary.withOpacity(0.5),
                ),
              ),
              title: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  convoProfile.when(
                    data: (profile) {
                      final roomId = convo.getRoomIdStr();
                      return Text(
                        profile.displayName ?? roomId,
                        overflow: TextOverflow.clip,
                        style: Theme.of(context).textTheme.bodyLarge,
                      );
                    },
                    skipLoadingOnReload: true,
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
                    skipLoadingOnReload: false,
                    error: (error, stackTrace) =>
                        Text('Error loading members count $error'),
                    loading: () => const CircularProgressIndicator(),
                  ),
                ],
              ),
              actions: [
                GestureDetector(
                  onTap: () {
                    inSideBar
                        ? ref
                            .read(hasExpandedPanel.notifier)
                            .update((state) => true)
                        : context.pushNamed(
                            Routes.chatProfile.name,
                            pathParameters: {'roomId': convo.getRoomIdStr()},
                          );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: SpaceParentBadge(
                      roomId: convo.getRoomIdStr(),
                      badgeSize: 20,
                      child: RoomAvatar(roomId: widget.convo.getRoomIdStr()),
                    ),
                  ),
                ),
              ],
            ),
            SliverFillRemaining(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                child: Chat(
                  keyboardDismissBehavior: Platform.isIOS
                      ? ScrollViewKeyboardDismissBehavior.onDrag
                      : ScrollViewKeyboardDismissBehavior.manual,
                  customBottomWidget:
                      CustomChatInput(key: Key(roomId), convo: convo),
                  textMessageBuilder: (
                    types.TextMessage m, {
                    required int messageWidth,
                    required bool showName,
                  }) =>
                      TextMessageBuilder(
                    convo: widget.convo,
                    message: m,
                    messageWidth: messageWidth,
                  ),
                  l10n: ChatL10nEn(
                    emptyChatPlaceholder: '',
                    attachmentButtonAccessibilityLabel: '',
                    fileButtonAccessibilityLabel: '',
                    inputPlaceholder: AppLocalizations.of(context)!.message,
                    sendButtonAccessibilityLabel: '',
                  ),
                  timeFormat: DateFormat.jm(),
                  messages: messages,
                  onSendPressed: (types.PartialText partialText) {},
                  user: types.User(id: client!.userId().toString()),
                  // disable image preview
                  disableImageGallery: true,
                  // custom avatar builder
                  avatarBuilder: (String userId) =>
                      AvatarBuilder(userId: userId),
                  isLastPage: !chatState.hasMore,
                  bubbleBuilder: (
                    Widget child, {
                    required types.Message message,
                    required bool nextMessageInGroup,
                  }) =>
                      GestureDetector(
                    onSecondaryTap: () {
                      showMessageOptions(context, message, roomId);
                    },
                    child: BubbleBuilder(
                      convo: convo,
                      message: message,
                      nextMessageInGroup: nextMessageInGroup,
                      enlargeEmoji: message.metadata!['enlargeEmoji'] ?? false,
                      child: child,
                    ),
                  ),
                  imageMessageBuilder: (
                    types.ImageMessage message, {
                    required int messageWidth,
                  }) =>
                      ImageMessageBuilder(
                    convo: convo,
                    message: message,
                    messageWidth: messageWidth,
                  ),
                  customMessageBuilder: (
                    types.CustomMessage message, {
                    required int messageWidth,
                  }) =>
                      CustomMessageBuilder(
                    message: message,
                    messageWidth: messageWidth,
                  ),
                  showUserAvatars: true,
                  onMessageLongPress: (
                    BuildContext context,
                    types.Message message,
                  ) async {
                    showMessageOptions(context, message, roomId);
                  },
                  onEndReached: ref
                      .read(chatStateProvider(convo).notifier)
                      .handleEndReached,
                  onEndReachedThreshold: 0.75,
                  onBackgroundTap: () {
                    final emojiRowVisible = ref.read(
                      chatInputProvider(roomId).select((ci) {
                        return ci.emojiRowVisible;
                      }),
                    );
                    final inputNotifier =
                        ref.read(chatInputProvider(roomId).notifier);
                    if (emojiRowVisible) {
                      inputNotifier.setCurrentMessageId(null);
                      inputNotifier.emojiRowVisible(false);
                    }
                  },
                  //Custom Theme class, see lib/common/store/chatTheme.dart
                  theme: const ActerChatTheme(
                    sendButtonIcon: Icon(Atlas.paper_airplane),
                    documentIcon: Icon(Atlas.file_thin, size: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
