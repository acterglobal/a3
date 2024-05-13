import 'dart:io';

import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/acter_theme.dart';
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
import 'package:acter/features/settings/providers/app_settings_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
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
  final bool inSidebar;

  const RoomPage({
    required this.roomId,
    required this.inSidebar,
    super.key = roomPageKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(chatProvider(roomId)).when(
          data: (convo) => ChatRoom(convo: convo, inSidebar: inSidebar),
          error: (e, s) => Center(
            child: Text(L10n.of(context).loadingRoomFailed(e)),
          ),
          loading: () => Center(child: Text(L10n.of(context).loading)),
        );
  }
}

class ChatRoom extends ConsumerStatefulWidget {
  final Convo convo;
  final bool inSidebar;

  const ChatRoom({
    required this.convo,
    required this.inSidebar,
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
    inputNotifier.setActionsMessage(message);
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) => Scaffold(
        resizeToAvoidBottomInset: orientation == Orientation.portrait,
        body: CustomScrollView(
          physics: const NeverScrollableScrollPhysics(),
          slivers: [appBar(context), chatBody(context)],
        ),
      ),
    );
  }

  SliverFillRemaining chatBody(BuildContext context) {
    final userAppSettings = ref.watch(userAppSettingsProvider);
    final chatState = ref.watch(chatStateProvider(widget.convo));
    final userId = ref.watch(myUserIdStrProvider);
    final roomId = widget.convo.getRoomIdStr();
    List<types.User> typingUsers = [];
    if (userAppSettings.valueOrNull != null) {
      final settings = userAppSettings.requireValue;
      if (settings.typingNotice() != false) {
        final typingEvent = ref.watch(chatTypingEventProvider);
        if (typingEvent.valueOrNull != null) {
          final t = typingEvent.requireValue;
          if (t != null) {
            if (t.roomId().toString() == roomId) {
              for (var i in t.userIds().toList()) {
                if (i.toString() != userId) {
                  final uid = types.User(
                    id: i.toString(),
                    firstName: i.toString(),
                  );
                  typingUsers.add(uid);
                }
              }
            }
          }
        }
      }
    }

    final messages = chatState.messages
        .where(
          // filter only items we can show
          (m) => m is! types.UnsupportedMessage,
        )
        .toList()
        .reversed
        .toList();

    return SliverFillRemaining(
      child: Container(
        decoration: const BoxDecoration(
          gradient: primaryGradient,
        ),
        child: Chat(
          keyboardDismissBehavior: Platform.isIOS
              ? ScrollViewKeyboardDismissBehavior.onDrag
              : ScrollViewKeyboardDismissBehavior.manual,
          customBottomWidget: CustomChatInput(
            key: Key('chat-input-$roomId'),
            roomId: widget.convo.getRoomIdStr(),
            onTyping: (typing) async {
              widget.convo.typingNotice(typing);
            },
          ),
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
            roomId: widget.convo.getRoomIdStr(),
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
            ref.read(chatInputProvider(roomId).notifier).unsetActions();
          },
          typingIndicatorOptions: TypingIndicatorOptions(
            typingMode: TypingIndicatorMode.name,
            typingUsers: typingUsers,
          ),
          //Custom Theme class, see lib/common/store/chatTheme.dart
          theme: Theme.of(context).chatTheme,
        ),
      ),
    );
  }

  SliverAppBar appBar(BuildContext context) {
    final roomId = widget.convo.getRoomIdStr();
    final convoProfile = ref.watch(chatProfileDataProvider(widget.convo));
    final activeMembers = ref.watch(membersIdsProvider(roomId));
    return SliverAppBar(
      elevation: 0,
      automaticallyImplyLeading: widget.inSidebar ? false : true,
      centerTitle: true,
      toolbarHeight: 70,
      flexibleSpace: FrostEffect(
        child: Container(),
      ),
      title: GestureDetector(
        onTap: () => context.pushNamed(
          Routes.chatProfile.name,
          pathParameters: {'roomId': roomId},
        ),
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
                L10n.of(context).errorLoadingProfile(error),
              ),
              loading: () => Skeletonizer(
                child: Text(L10n.of(context).loading),
              ),
            ),
            const SizedBox(height: 5),
            activeMembers.when(
              data: (members) {
                int count = members.length;
                return Text(
                  L10n.of(context).membersCount(count),
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
              skipLoadingOnReload: false,
              error: (error, stackTrace) => Text(
                L10n.of(context).errorLoadingMembersCount(error),
              ),
              loading: () => Skeletonizer(
                child: Text(L10n.of(context).membersCount(100)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        GestureDetector(
          onTap: () => context.pushNamed(
            Routes.chatProfile.name,
            pathParameters: {'roomId': roomId},
          ),
          child: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: RoomAvatar(
              roomId: roomId,
              showParent: true,
            ),
          ),
        ),
      ],
    );
  }
}
