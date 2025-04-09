import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/network_provider.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/features/chat/models/chat_input_state/chat_input_state.dart';
import 'package:acter/features/chat/models/chat_room_state/chat_room_state.dart';
import 'package:acter/features/chat/models/media_chat_state/media_chat_state.dart';
import 'package:acter/features/chat/models/room_list_filter_state/room_list_filter_state.dart';
import 'package:acter/features/chat/providers/notifiers/chat_input_notifier.dart';
import 'package:acter/features/chat/providers/notifiers/chat_room_notifier.dart';
import 'package:acter/features/chat/providers/notifiers/media_chat_notifier.dart';
import 'package:acter/features/chat/providers/room_list_filter_provider.dart';
import 'package:acter/features/chat/utils.dart';
import 'package:acter/features/chat_ui_showcase/models/convo_showcase_list.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:acter/features/settings/providers/app_settings_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:riverpod/riverpod.dart';

final autoDownloadMediaProvider = FutureProvider.family<bool, String>((
  ref,
  roomId,
) async {
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
    StateNotifierProvider.autoDispose<ChatInputNotifier, ChatInputState>(
      (ref) => ChatInputNotifier(),
    );

final chatStateProvider =
    StateNotifierProvider.family<ChatRoomNotifier, ChatRoomState, String>(
      (ref, roomId) => ChatRoomNotifier(ref: ref, roomId: roomId),
    );

final chatTopic = FutureProvider.autoDispose.family<String?, String>((
  ref,
  roomId,
) async {
  final c = await ref.watch(chatProvider(roomId).future);
  return c?.topic();
});

bool msgFilter(types.Message m) {
  return m is! types.UnsupportedMessage &&
      !(m is types.CustomMessage && !renderCustomMessageBubble(m));
}

final renderableChatMessagesProvider = StateProvider.autoDispose
    .family<List<Message>, String>((ref, roomId) {
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

final chatMessagesProvider = StateProvider.autoDispose
    .family<List<Message>, String>((ref, roomId) {
      final moreMessages = [];
      if (ref.watch(
        chatStateProvider(roomId).select((value) => !value.hasMore),
      )) {
        moreMessages.add(
          const types.SystemMessage(
            id: 'chat-invite',
            text: 'invite',
            metadata: {'type': '_invite'},
          ),
        );

        // we have reached the end, show topic
        final topic = ref.watch(chatTopic(roomId)).valueOrNull;
        if (topic != null) {
          moreMessages.add(
            types.SystemMessage(
              id: 'chat-topic',
              text: topic,
              metadata: const {'type': '_topic'},
            ),
          );
        }

        // and encryption information block
        if (ref.watch(isRoomEncryptedProvider(roomId)).valueOrNull == true) {
          moreMessages.add(
            const types.SystemMessage(
              id: 'encrypted-information',
              text: '',
              metadata: {'type': '_encryptedInfo'},
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

final isAuthorOfSelectedMessage = StateProvider.autoDispose<bool>((ref) {
  final chatInputState = ref.watch(chatInputProvider);
  final myUserId = ref.watch(myUserIdStrProvider);
  return chatInputState.selectedMessage?.author.id == myUserId;
});

final mediaChatStateProvider = StateNotifierProvider.family<
  MediaChatNotifier,
  MediaChatState,
  ChatMessageInfo
>((ref, messageInfo) => MediaChatNotifier(ref: ref, messageInfo: messageInfo));

final timelineStreamProvider = FutureProvider.family<TimelineStream, String>((
  ref,
  roomId,
) async {
  final chat = await ref.watch(chatProvider(roomId).future);
  if (chat == null) {
    throw RoomNotFound();
  }
  return chat.timelineStream();
});

final filteredChatsProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  final allRooms = ref.watch(chatIdsProvider);
  if (!ref.watch(hasRoomFilters)) {
    throw 'No filters selected';
  }

  final foundRooms = List<String>.empty(growable: true);

  final search = ref.watch(roomListFilterProvider);
  for (final convoId in allRooms) {
    if (await roomListFilterStateAppliesToRoom(search, ref, convoId)) {
      foundRooms.add(convoId);
    }
  }

  return foundRooms;
});

// get status of room encryption
final isRoomEncryptedProvider = FutureProvider.family<bool, String>((
  ref,
  roomId,
) async {
  final convo = await ref.watch(chatProvider(roomId).future);
  // FIXME: unify this over all rooms.
  return (await convo?.isEncrypted()) == true;
});

final chatTypingEventProvider = StreamProvider.autoDispose
    .family<List<types.User>, String>((ref, roomId) async* {
      // if we are in chat showcase mode, return mock typing users
      if (includeChatShowcase &&
          mockChatList.any((mockChatItem) => mockChatItem.roomId == roomId)) {
        final mockChatItem = mockChatList.firstWhere(
          (mockChatItem) => mockChatItem.roomId == roomId,
        );
        yield mockChatItem.typingUsers ?? [];
        return;
      }

      // otherwise, get the typing users from the client
      final client = await ref.watch(alwaysClientProvider.future);
      final userId = ref.watch(myUserIdStrProvider);
      yield [];
      await for (final event in client.subscribeToTypingEventStream(roomId)) {
        yield event
            .userIds()
            .toList()
            .map((i) => i.toString())
            .where((id) => id != userId) // remove our User ID
            .map((id) => types.User(id: id, firstName: id))
            .toList();
      }
    });

// unread notifications, unread mentions, unread messages
typedef UnreadCounters = (int, int, int);

final unreadCountersProvider = FutureProvider.family<UnreadCounters, String>((
  ref,
  roomId,
) async {
  final convo = await ref.watch(chatProvider(roomId).future);
  if (convo == null) {
    return (0, 0, 0);
  }
  final ret = (
    convo.numUnreadNotificationCount(),
    convo.numUnreadMentions(),
    convo.numUnreadMessages(),
  );
  return ret;
});

final hasUnreadMessages = FutureProvider.family<bool, String>((
  ref,
  roomId,
) async {
  final unreadCounters = ref.watch(unreadCountersProvider(roomId)).valueOrNull;

  if (unreadCounters == null) return false;

  final (notifications, mentions, messages) = unreadCounters;
  return notifications > 0 || mentions > 0 || messages > 0;
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

final subChatsListProvider = FutureProvider.family<List<String>, String>((
  ref,
  spaceId,
) async {
  List<String> subChatsList = [];

  //Get known sub-chats
  final spaceRelationsOverview = await ref.watch(
    spaceRelationsOverviewProvider(spaceId).future,
  );
  subChatsList.addAll(spaceRelationsOverview.knownChats);

  //Get more sub-chats
  final relatedChatsLoader = await ref.watch(
    remoteChatRelationsProvider(spaceId).future,
  );
  for (var element in relatedChatsLoader) {
    subChatsList.add(element.roomIdStr());
  }

  return subChatsList;
});

// useful for disabling send button for short time while message is preparing to be sent
final allowSendInputProvider = StateProvider.family.autoDispose<bool, String>(
  (ref, roomId) => ref.watch(
    chatInputProvider.select(
      (state) => state.sendingState == SendingState.preparing,
    ),
  ),
);

// whether user has enough permissions to send message in room
final canSendMessageProvider = FutureProvider.family<bool?, String>((
  ref,
  roomId,
) async {
  final membership = ref.watch(roomMembershipProvider(roomId));
  return membership.valueOrNull?.canString('CanSendChatMessages');
});
