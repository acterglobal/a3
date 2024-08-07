import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/network_provider.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/models/chat_input_state/chat_input_state.dart';
import 'package:acter/features/chat/models/chat_room_state/chat_room_state.dart';
import 'package:acter/features/chat/models/media_chat_state/media_chat_state.dart';
import 'package:acter/features/chat/models/room_list_filter_state/room_list_filter_state.dart';
import 'package:acter/features/chat/providers/notifiers/chat_input_notifier.dart';
import 'package:acter/features/chat/providers/notifiers/chat_room_notifier.dart';
import 'package:acter/features/chat/providers/notifiers/media_chat_notifier.dart';
import 'package:acter/features/chat/providers/room_list_filter_provider.dart';
import 'package:acter/features/chat/utils.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/settings/providers/app_settings_provider.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:riverpod/riverpod.dart';

final autoDownloadMediaProvider =
    FutureProvider.family<bool, String>((ref, roomId) async {
  // this should also check for local room settings...
  final userSettings = await ref.read(userAppSettingsProvider.future);
  final globalAutoDownload = (userSettings.autoDownloadChat() ?? 'always');
  if (globalAutoDownload == 'wifiOnly') {
    return ref.watch(hasWifiNetworkProvider);
  }

  return globalAutoDownload == 'always';
});

// keep track of text controller values across rooms.
final chatInputProvider =
    StateNotifierProvider<ChatInputNotifier, ChatInputState>(
  (ref) => ChatInputNotifier(),
);

final chatStateProvider =
    StateNotifierProvider.family<ChatRoomNotifier, ChatRoomState, String>(
  (ref, roomId) => ChatRoomNotifier(ref: ref, roomId: roomId),
);

final chatTopic =
    FutureProvider.autoDispose.family<String?, String>((ref, roomId) async {
  final c = await ref.watch(chatProvider(roomId).future);
  return c?.topic();
});

bool msgFilter(types.Message m) {
  return m is! types.UnsupportedMessage &&
      !(m is types.CustomMessage && !renderCustomMessageBubble(m));
}

final renderableChatMessagesProvider =
    StateProvider.autoDispose.family<List<Message>, String>((ref, roomId) {
  return ref
      .watch(chatStateProvider(roomId).select((value) => value.messages))
      .where(
        // filter only items we can show
        msgFilter,
      )
      .toList()
      .reversed
      .toList();
});

final latestTrackableMessageId =
    StateProvider.autoDispose.family<String?, String>((ref, roomId) {
  return ref.watch(
    chatStateProvider(roomId).select(
      (value) =>
          // find the last remote item we can use for tracking
          value.messages.lastOrNull?.remoteId,
    ),
  );
});

final chatMessagesProvider =
    StateProvider.autoDispose.family<List<Message>, String>((ref, roomId) {
  final moreMessages = [];
  if (ref.watch(chatStateProvider(roomId).select((value) => !value.hasMore))) {
    moreMessages.add(
      const types.SystemMessage(
        id: 'chat-invite',
        text: 'invite',
        metadata: {
          'type': '_invite',
        },
      ),
    );

    // we have reached the end, show topic
    final topic = ref.watch(chatTopic(roomId)).valueOrNull;
    if (topic != null) {
      moreMessages.add(
        types.SystemMessage(
          id: 'chat-topic',
          text: topic,
          metadata: const {
            'type': '_topic',
          },
        ),
      );
    }

    // and encryption information block
    if (ref.watch(isRoomEncryptedProvider(roomId)).valueOrNull == true) {
      moreMessages.add(
        const types.SystemMessage(
          id: 'encrypted-information',
          text: '',
          metadata: {
            'type': '_encryptedInfo',
          },
        ),
      );
    }
  }
  final messages = ref.watch(renderableChatMessagesProvider(roomId));
  if (moreMessages.isEmpty) {
    return messages;
  }
  // return as a new list to ensure the provider is properly resetting
  return [...messages, ...moreMessages];
});

final isAuthorOfSelectedMessage = StateProvider<bool>((ref) {
  final chatInputState = ref.watch(chatInputProvider);
  final myUserId = ref.watch(myUserIdStrProvider);
  return chatInputState.selectedMessage?.author.id == myUserId;
});

final mediaChatStateProvider = StateNotifierProvider.family<MediaChatNotifier,
    MediaChatState, ChatMessageInfo>(
  (ref, messageInfo) => MediaChatNotifier(ref: ref, messageInfo: messageInfo),
);

final timelineStreamProvider =
    FutureProvider.family<TimelineStream, String>((ref, roomId) async {
  final chat = await ref.watch(chatProvider(roomId).future);
  if (chat == null) {
    throw RoomNotFound();
  }
  return chat.timelineStream();
});

final filteredChatsProvider =
    FutureProvider.autoDispose<List<Convo>>((ref) async {
  final allRooms = ref.watch(chatsProvider);
  if (!ref.watch(hasRoomFilters)) {
    throw 'No filters selected';
  }

  final foundRooms = List<Convo>.empty(growable: true);

  final search = ref.watch(roomListFilterProvider);
  for (final convo in allRooms) {
    if (await roomListFilterStateAppliesToRoom(search, ref, convo)) {
      foundRooms.add(convo);
    }
  }

  return foundRooms;
});

// get status of room encryption
final isRoomEncryptedProvider =
    FutureProvider.family<bool, String>((ref, roomId) async {
  final convo = await ref.watch(chatProvider(roomId).future);
  // FIXME: unify this over all rooms.
  return (await convo?.isEncrypted()) == true;
});

final chatTypingEventProvider = StreamProvider.autoDispose
    .family<List<types.User>, String>((ref, roomId) async* {
  final client = ref.watch(alwaysClientProvider);
  final userId = ref.watch(myUserIdStrProvider);
  yield [];
  await for (final event in client.subscribeToTypingEventStream(roomId)) {
    yield event
        .userIds()
        .toList()
        .map((i) => i.toString())
        .where((id) => id != userId) // remove our User ID
        .map(
          (id) => types.User(
            id: id,
            firstName: id,
          ),
        )
        .toList();
  }
});

// unread notifications, unread mentions, unread messages
typedef UnreadCounters = (int, int, int);

final unreadCountersProvider =
    FutureProvider.family<UnreadCounters, String>((ref, roomId) async {
  final convo = await ref.watch(
    chatProvider(roomId).future,
  );
  if (convo == null) {
    return (0, 0, 0);
  }
  final ret = (
    convo.numUnreadNotificationCount(),
    convo.numUnreadMentions(),
    convo.numUnreadMessages()
  );
  return ret;
});

final hasUnreadChatsProvider = FutureProvider.autoDispose((ref) async {
  if (!ref.watch(isActiveProvider(LabsFeature.chatUnread))) {
    // feature not active

    return UrgencyBadge.none;
  }
  final chats = ref.watch(chatIdsProvider);
  if (chats.isEmpty) {
    return UrgencyBadge.none;
  }
  UrgencyBadge currentBadge = UrgencyBadge.none;

  for (final chat in chats) {
    // this is highly inefficient
    final unreadCounter = await ref.watch(unreadCountersProvider(chat).future);
    if (unreadCounter.$1 > 0) {
      // mentions, we just blurb
      return UrgencyBadge.important;
    }
    if (unreadCounter.$2 > 0) {
      //
      currentBadge = UrgencyBadge.unread;
    }
  }
  return currentBadge;
});
