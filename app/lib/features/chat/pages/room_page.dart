import 'dart:io';

import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/chat_theme.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/frost_effect.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/avatar_builder.dart';
import 'package:acter/features/chat/widgets/bubble_builder.dart';
import 'package:acter/features/chat/widgets/custom_input.dart';
import 'package:acter/features/chat/widgets/custom_message_builder.dart';
import 'package:acter/features/chat/widgets/file_message_builder.dart';
import 'package:acter/features/chat/widgets/image_message_builder.dart';
import 'package:acter/features/chat/widgets/room_avatar.dart';
import 'package:acter/features/chat/widgets/text_message_builder.dart';
import 'package:acter/features/chat/widgets/video_message_builder.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

class RoomPage extends ConsumerWidget {
  static const roomPageKey = Key('chat-room-page');
  final String roomId;

  const RoomPage({
    required this.roomId,
    super.key = roomPageKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(chatProvider(roomId)).when(
          data: (convo) => ChatRoom(convo: convo),
          error: (e, s) => Center(
              child: Text('${L10n.of(context).loadingFailed('room')}: $e')),
          loading: () => Center(child: Text(L10n.of(context).loading(''))),
        );
  }
}

class ChatRoom extends ConsumerStatefulWidget {
  final Convo convo;

  const ChatRoom({
    required this.convo,
    super.key,
  });

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
    final userId = ref.read(myUserIdStrProvider);
    if (userId == message.author.id && message is types.TextMessage) {
      inputNotifier.showEditButton(true);
    } else {
      inputNotifier.showEditButton(false);
    }
    if (ref.read(chatInputProvider(roomId)).showReplyView) {
      inputNotifier.showReplyView(false);
      inputNotifier.setReplyWidget(null);
      inputNotifier.setEditWidget(null);
    }
    inputNotifier.setCurrentMessageId(message.id);
    inputNotifier.emojiRowVisible(true);
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(myUserIdStrProvider);
    final roomId = widget.convo.getRoomIdStr();
    final inSideBar = ref.watch(inSideBarProvider);
    final convoProfile = ref.watch(chatProfileDataProvider(widget.convo));
    final activeMembers = ref.watch(membersIdsProvider(roomId));
    final chatState = ref.watch(chatStateProvider(widget.convo));
    final messages = chatState.messages
        .where(
          // filter only items we can show
          (m) => m is! types.UnsupportedMessage,
        )
        .toList()
        .reversed
        .toList();

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
                child: Container(),
              ),
              title: GestureDetector(
                onTap: () {
                  inSideBar
                      ? ref
                          .read(hasExpandedPanel.notifier)
                          .update((state) => true)
                      : context.pushNamed(
                          Routes.chatProfile.name,
                          pathParameters: {'roomId': roomId},
                        );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    convoProfile.when(
                      data: (profile) => Text(
                        profile.displayName ?? roomId,
                        overflow: TextOverflow.clip,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      skipLoadingOnReload: true,
                      error: (error, stackTrace) => Text(
                        '${L10n.of(context).errorLoading('profile')} $error',
                      ),
                      loading: () => Skeletonizer(
                        child: Text(L10n.of(context).loading('')),
                      ),
                    ),
                    const SizedBox(height: 5),
                    activeMembers.when(
                      data: (members) {
                        int count = members.length;
                        return Text(
                          '$count ${L10n.of(context).members}',
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      },
                      skipLoadingOnReload: false,
                      error: (error, stackTrace) =>
                          Text('${L10n.of(context).errorLoading('membersCount')} $error'),
                      loading: () => Skeletonizer(
                        child: Text(
                          '100 ${L10n.of(context).members}',
                        ),
                      ),
                    ),
                  ],
                ),
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
                            pathParameters: {'roomId': roomId},
                          );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: RoomAvatar(
                      roomId: roomId,
                      showParent: true,
                    ),
                  ),
                ),
              ],
            ),
            SliverFillRemaining(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: primaryGradient,
                ),
                child: Chat(
                  keyboardDismissBehavior: Platform.isIOS
                      ? ScrollViewKeyboardDismissBehavior.onDrag
                      : ScrollViewKeyboardDismissBehavior.manual,
                  customBottomWidget:
                      CustomChatInput(key: Key(roomId), convo: widget.convo),
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
                    inputPlaceholder: L10n.of(context).message,
                    sendButtonAccessibilityLabel: '',
                  ),
                  timeFormat: DateFormat.jm(),
                  messages: messages,
                  onSendPressed: (types.PartialText partialText) {},
                  user: types.User(id: userId),
                  // disable image preview
                  disableImageGallery: true,
                  // custom avatar builder
                  avatarBuilder: (types.User user) =>
                      AvatarBuilder(userId: user.id, roomId: roomId),
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
                      convo: widget.convo,
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
                    convo: widget.convo,
                    message: message,
                    messageWidth: messageWidth,
                  ),
                  videoMessageBuilder: (
                    types.VideoMessage message, {
                    required int messageWidth,
                  }) =>
                      VideoMessageBuilder(
                    convo: widget.convo,
                    message: message,
                    messageWidth: messageWidth,
                  ),
                  fileMessageBuilder: (
                    types.FileMessage message, {
                    required messageWidth,
                  }) {
                    return FileMessageBuilder(
                      convo: widget.convo,
                      message: message,
                      messageWidth: messageWidth,
                    );
                  },
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
                      .read(chatStateProvider(widget.convo).notifier)
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
