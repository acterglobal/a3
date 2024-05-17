import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/network_provider.dart';
import 'package:acter/common/providers/room_providers.dart';
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
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:riverpod/riverpod.dart';

final autoDownloadMediaProvider =
    FutureProvider.family<bool, String>((ref, roomId) async {
  // this should also check for local room settings...
  final userSettings = await ref.read(userAppSettingsProvider.future);
  final globalAutoDownload = (userSettings.autoDownloadChat() ?? 'always');
  if (globalAutoDownload == 'wifiOnly') {
    final con = await ref.watch(networkConnectivityProvider.future);
    return con == ConnectivityResult.wifi;
  }

  return globalAutoDownload == 'always';
});

// keep track of text controller values across rooms.
final chatInputProvider =
    StateNotifierProvider.family<ChatInputNotifier, ChatInputState, String>(
  (ref, roomId) => ChatInputNotifier(),
);

final chatStateProvider =
    StateNotifierProvider.family<ChatRoomNotifier, ChatRoomState, Convo>(
  (ref, convo) => ChatRoomNotifier(ref: ref, convo: convo),
);

final chatIsEncrypted =
    FutureProvider.autoDispose.family<bool, Convo>((ref, convo) async {
  final c = await ref.watch(convoProvider(convo).future);
  if (c == null) {
    return false;
  }
  return await c.isEncrypted();
});

final chatTopic =
    FutureProvider.autoDispose.family<String?, Convo>((ref, convo) async {
  final c = await ref.watch(convoProvider(convo).future);
  return c?.topic();
});

final renderableChatMessagesProvider =
    StateProvider.autoDispose.family<List<Message>, Convo>((ref, convo) {
  return ref
      .watch(chatStateProvider(convo).select((value) => value.messages))
      .where(
        // filter only items we can show
        (m) =>
            m is! types.UnsupportedMessage &&
            !(m is types.CustomMessage && !renderCustomMessageBubble(m)),
      )
      .toList()
      .reversed
      .toList();
});

final chatMessagesProvider =
    StateProvider.autoDispose.family<List<Message>, Convo>((ref, convo) {
  final messages = ref.watch(renderableChatMessagesProvider(convo));
  if (ref.watch(chatStateProvider(convo).select((value) => !value.hasMore))) {
    // we have reached the end, show topic
    final topic = ref.watch(chatTopic(convo)).valueOrNull;
    if (topic != null) {
      messages.add(
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
    if (ref.watch(chatIsEncrypted(convo)).valueOrNull == true) {
      messages.add(
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
  return messages;
});

final isAuthorOfSelectedMessage =
    StateProvider.family<bool, String>((ref, roomId) {
  final chatInputState = ref.watch(chatInputProvider(roomId));
  final myUserId = ref.watch(myUserIdStrProvider);
  return chatInputState.selectedMessage?.author.id == myUserId;
});

final mediaChatStateProvider = StateNotifierProvider.family<MediaChatNotifier,
    MediaChatState, ChatMessageInfo>(
  (ref, messageInfo) => MediaChatNotifier(ref: ref, messageInfo: messageInfo),
);

final timelineStreamProvider = StateProvider.family<TimelineStream, Convo>(
  (ref, convo) => convo.timelineStream(),
);

final timelineStreamProviderForId =
    FutureProvider.family<TimelineStream, String>((ref, roomId) async {
  final chat = await ref.watch(chatProvider(roomId).future);
  return ref.watch(timelineStreamProvider(chat));
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
  return await convo.isEncrypted();
});

typedef Mentions = List<Map<String, String>>;

final chatMentionsProvider =
    FutureProvider.autoDispose.family<Mentions, String>((ref, roomId) async {
  final activeMembers = await ref.read(membersIdsProvider(roomId).future);
  List<Map<String, String>> mentionRecords = [];
  for (final mId in activeMembers) {
    final data = await ref
        .watch(roomMemberProvider((roomId: roomId, userId: mId)).future);
    Map<String, String> record = {};
    final displayName = data.profile.displayName;
    record['id'] = mId;
    if (displayName != null) {
      record['displayName'] = displayName;
      // all of our search terms:
      record['display'] = displayName;
    } else {
      record['display'] = mId;
    }
    mentionRecords.add(record);
  }
  return mentionRecords;
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
