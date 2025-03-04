import 'dart:io';

import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/acter_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/frost_effect.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/avatar_builder.dart';
import 'package:acter/features/chat/widgets/bubble_builder.dart';
import 'package:acter/features/chat/widgets/custom_input.dart';
import 'package:acter/features/chat/widgets/custom_message_builder.dart';
import 'package:acter/features/chat/widgets/file_message_builder.dart';
import 'package:acter/features/chat/widgets/image_message_builder.dart';
import 'package:acter/features/chat/widgets/messages/encrypted_info.dart';
import 'package:acter/features/chat/widgets/messages/invite.dart';
import 'package:acter/features/chat/widgets/messages/topic.dart';
import 'package:acter/features/chat/widgets/room_avatar.dart';
import 'package:acter/features/chat/widgets/text_message_builder.dart';
import 'package:acter/features/chat/widgets/video_message_builder.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:acter/features/settings/providers/app_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::chat::room');

class RoomPage extends ConsumerWidget {
  static const roomPageKey = Key('chat-room-page');

  final String roomId;

  const RoomPage({
    super.key = roomPageKey,
    required this.roomId,
  });

  Widget appBar(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    final roomAvatarInfo = ref.watch(roomAvatarInfoProvider(roomId));
    final membersLoader = ref.watch(membersIdsProvider(roomId));
    final isEncrypted =
        ref.watch(isRoomEncryptedProvider(roomId)).valueOrNull ?? false;
    return AppBar(
      elevation: 0,
      automaticallyImplyLeading: !context.isLargeScreen,
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
            Text(
              roomAvatarInfo.displayName ?? roomId,
              overflow: TextOverflow.clip,
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 5),
            membersLoader.when(
              data: (members) => Text(
                lang.membersCount(members.length),
                style: textTheme.bodySmall,
              ),
              skipLoadingOnReload: false,
              error: (e, s) {
                _log.severe('Failed to load active members', e, s);
                return Text(lang.errorLoadingMembersCount(e));
              },
              loading: () => Skeletonizer(
                child: Text(lang.membersCount(100)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (!isEncrypted)
          IconButton(
            onPressed: () => EasyLoading.showInfo(lang.chatNotEncrypted),
            icon: Icon(
              PhosphorIcons.shieldWarning(),
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        GestureDetector(
          onTap: () => context.pushNamed(
            Routes.chatProfile.name,
            pathParameters: {'roomId': roomId},
          ),
          child: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: RoomAvatar(
              roomId: roomId,
              showParents: true,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OrientationBuilder(
      builder: (context, orientation) => Scaffold(
        resizeToAvoidBottomInset: orientation == Orientation.portrait,
        body: Column(
          children: [
            appBar(context, ref),
            ChatRoom(roomId: roomId),
            chatInput(context, ref),
          ],
        ),
      ),
    );
  }

  Widget chatInput(BuildContext context, WidgetRef ref) {
    final sendTypingNotice = ref.watch(
      userAppSettingsProvider.select(
        (settings) => settings.valueOrNull?.typingNotice() ?? false,
      ),
    );
    return CustomChatInput(
      key: Key('chat-input-$roomId'),
      roomId: roomId,
      onTyping: (typing) async {
        if (sendTypingNotice) {
          final chat = await ref.read(chatProvider(roomId).future);
          await chat?.typingNotice(typing);
        }
      },
    );
  }
}

class ChatRoom extends ConsumerStatefulWidget {
  final String roomId;

  const ChatRoom({
    super.key,
    required this.roomId,
  });

  @override
  ConsumerState<ChatRoom> createState() => _ChatRoomConsumerState();
}

class _ChatRoomConsumerState extends ConsumerState<ChatRoom> {
  AutoScrollController scrollController = AutoScrollController();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() async {
      if (!ref.watch(isActiveProvider(LabsFeature.chatUnread))) {
        if (ref.read(hasUnreadMessages(widget.roomId)).valueOrNull ?? false) {
          // debounce
          await Future.delayed(const Duration(milliseconds: 300), () async {
            final roomId = widget.roomId;
            // this might be a bit too simple ...
            if (scrollController.offset == 0) {
              final timeline =
                  await ref.read(timelineStreamProvider(roomId).future);
              await timeline.markAsRead(true);
            }
          });
        }
      }
    });
  }

  void showMessageOptions(BuildContext context, types.Message message) {
    if (message is types.CustomMessage) {
      if (message.metadata?['eventType'] == 'm.room.redaction') return;
    }
    final inputNotifier = ref.read(chatInputProvider.notifier);
    inputNotifier.setActionsMessage(message);
  }

  Widget _renderLoading(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: ListView.builder(
          itemCount: 5,
          shrinkWrap: true,
          itemBuilder: (context, index) => const Skeletonizer.zone(
            child: Card(
              child: ListTile(
                leading: Bone.circle(size: 48),
                title: Bone.text(words: 2),
                subtitle: Bone.text(),
                trailing: Bone.icon(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomId = widget.roomId;
    final messages = ref.watch(chatMessagesProvider(roomId));

    if (messages.isEmpty) {
      return _renderLoading(context);
    }

    final endReached =
        ref.watch(chatStateProvider(roomId).select((c) => !c.hasMore));
    final userId = ref.watch(myUserIdStrProvider);
    final isDirectChat =
        ref.watch(isDirectChatProvider(roomId)).valueOrNull ?? false;
    final typingUsers =
        ref.watch(chatTypingEventProvider(roomId)).valueOrNull ?? [];

    return Expanded(
      child: Chat(
        keyboardDismissBehavior: Platform.isIOS
            ? ScrollViewKeyboardDismissBehavior.onDrag
            : ScrollViewKeyboardDismissBehavior.manual,
        customBottomWidget: const SizedBox.shrink(),
        scrollController: scrollController,
        textMessageBuilder: (
          types.TextMessage msg, {
          required int messageWidth,
          required bool showName,
        }) {
          return TextMessageBuilder(
            roomId: widget.roomId,
            message: msg,
            messageWidth: messageWidth,
          );
        },
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
        avatarBuilder: (types.User user) => AvatarBuilder(
          userId: user.id,
          roomId: roomId,
        ),
        isLastPage: endReached,
        bubbleBuilder: (
          Widget child, {
          required types.Message message,
          required bool nextMessageInGroup,
        }) {
          return GestureDetector(
            onSecondaryTap: () => showMessageOptions(context, message),
            child: BubbleBuilder(
              roomId: widget.roomId,
              message: message,
              nextMessageInGroup: nextMessageInGroup,
              enlargeEmoji: message.metadata?['enlargeEmoji'] == true,
              child: child,
            ),
          );
        },
        imageMessageBuilder: (
          types.ImageMessage message, {
          required int messageWidth,
        }) {
          return ImageMessageBuilder(
            roomId: widget.roomId,
            message: message,
            messageWidth: messageWidth,
          );
        },
        videoMessageBuilder: (
          types.VideoMessage message, {
          required int messageWidth,
        }) {
          return VideoMessageBuilder(
            roomId: widget.roomId,
            message: message,
            messageWidth: messageWidth,
          );
        },
        fileMessageBuilder: (
          types.FileMessage message, {
          required messageWidth,
        }) {
          return FileMessageBuilder(
            roomId: widget.roomId,
            message: message,
            messageWidth: messageWidth,
          );
        },
        customMessageBuilder: (
          types.CustomMessage message, {
          required int messageWidth,
        }) {
          return CustomMessageBuilder(
            message: message,
            messageWidth: messageWidth,
          );
        },
        systemMessageBuilder: (msg) => renderSysMessage(context, msg),
        showUserAvatars: !isDirectChat,
        onMessageLongPress: showMessageOptions,
        onEndReached: ref
            .read(chatStateProvider(widget.roomId).notifier)
            .handleEndReached,
        onEndReachedThreshold: 0.75,
        onBackgroundTap: ref.read(chatInputProvider.notifier).unsetActions,
        typingIndicatorOptions: TypingIndicatorOptions(
          animationSpeed: const Duration(seconds: 1),
          typingMode: TypingIndicatorMode.name,
          typingUsers: typingUsers,
        ),
        //Custom Theme class, see lib/common/store/chatTheme.dart
        theme: Theme.of(context).chatTheme,
      ),
    );
  }

  Widget renderSysMessage(BuildContext context, types.SystemMessage message) {
    return switch (message.metadata?['type']) {
      '_invite' => InviteSystemMessageWidget(
          message: message,
          roomId: widget.roomId,
        ),
      '_topic' => TopicSystemMessageWidget(
          message: message,
          roomId: widget.roomId,
        ),
      '_read_marker' => Center(
          child: Divider(color: Theme.of(context).indicatorColor),
        ),
      '_encryptedInfo' => const EncryptedInfoWidget(),
      _ => SystemMessage(
          key: Key('chat-room-${message.id}'),
          message: message.text,
        )
    };
  }
}
