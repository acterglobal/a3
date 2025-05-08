import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/html_editor/models/mention_type.dart';
import 'package:acter/features/chat_ng/models/chat_editor_state.dart';
import 'package:acter/features/chat_ng/models/chat_room_state/chat_room_state.dart';
import 'package:acter/features/chat_ng/models/replied_to_msg_state.dart';
import 'package:acter/features/chat_ng/providers/notifiers/chat_editor_notifier.dart';
import 'package:acter/features/chat_ng/providers/notifiers/chat_room_messages_notifier.dart';
import 'package:acter/features/chat_ng/providers/notifiers/reply_messages_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::chat::message_provider');
const _supportedTypes = [
  'MembershipChange',
  'ProfileChange',

  'm.policy.rule.room',
  'm.policy.rule.server',
  'm.policy.rule.user',
  'm.room.avatar',
  'm.room.create',
  'm.room.encryption',
  'm.room.guest_access',
  'm.room.history_visibility',
  'm.room.join_rules',
  'm.room.name',
  'm.room.pinned_events',
  'm.room.power_levels',
  'm.room.server_acl',
  'm.room.tombstone',
  'm.room.topic',
  'm.space.child',
  'm.space.parent',

  'm.room.message',
  'm.room.redaction',
  'm.room.encrypted',
];

typedef RoomMsgId = ({String roomId, String uniqueId});
typedef MentionQuery = (String, MentionType);
typedef ReactionItem = (String, List<ReactionRecord>);

final chatMessagesStateProvider = StateNotifierProvider.family<
  ChatRoomMessagesNotifier,
  ChatRoomState,
  String
>((ref, roomId) => ChatRoomMessagesNotifier(ref: ref, roomId: roomId));

final chatRoomMessageProvider = StateProvider.family<TimelineItem?, RoomMsgId>((
  ref,
  roomMsgId,
) {
  final chatRoomState = ref.watch(chatMessagesStateProvider(roomMsgId.roomId));
  return chatRoomState.message(roomMsgId.uniqueId);
});

final showHiddenMessages = StateProvider((ref) => false);

final animatedListChatMessagesProvider =
    StateProvider.family<GlobalKey<AnimatedListState>, String>(
      (ref, roomId) =>
          ref.watch(chatMessagesStateProvider(roomId).notifier).animatedList,
    );

final renderableChatMessagesProvider = StateProvider.autoDispose
    .family<List<String>, String>((ref, roomId) {
      final msgList = ref.watch(
        chatMessagesStateProvider(roomId).select((value) => value.messageList),
      );
      if (ref.watch(showHiddenMessages)) {
        // do not apply filters
        return msgList;
      }
      // do apply some filters

      return msgList.where((id) {
        final msg = ref.watch(
          chatRoomMessageProvider((roomId: roomId, uniqueId: id)),
        );
        if (msg == null) {
          _log.severe('Room Msg $roomId $id not found');
          return false;
        }
        return _supportedTypes.contains(msg.eventItem()?.eventType());
      }).toList();
    });

final renderableBubbleChatMessagesProvider = StateProvider.autoDispose
    .family<List<String>, String>((ref, roomId) {
      final msgList = ref.watch(
        chatMessagesStateProvider(roomId).select((value) => value.messageList),
      );
      if (ref.watch(showHiddenMessages)) {
        // do not apply filters
        return msgList;
      }
      // do apply some filters

      return msgList.where((id) {
        final msg = ref.watch(
          chatRoomMessageProvider((roomId: roomId, uniqueId: id)),
        );
        if (msg == null) {
          _log.severe('Room Msg $roomId $id not found');
          return false;
        }
        return [
          'm.room.message',
          'm.room.encrypted',
          'm.room.encrypted',
        ].contains(msg.eventItem()?.eventType());
      }).toList();
    });

final _getNextMessageProvider = Provider.family<TimelineItem?, RoomMsgId>((
  ref,
  roomMsgId,
) {
  final roomId = roomMsgId.roomId;
  final eventId = roomMsgId.uniqueId;
  final messages = ref.watch(renderableBubbleChatMessagesProvider(roomId));
  final index = messages.indexOf(eventId);
  if (index == -1) return null;
  if (index == messages.length - 1) return null;
  return ref.watch(
    chatRoomMessageProvider((roomId: roomId, uniqueId: messages[index + 1])),
  );
});

final _getPreviousMessageProvider = Provider.family<TimelineItem?, RoomMsgId>((
  ref,
  roomMsgId,
) {
  final roomId = roomMsgId.roomId;
  final eventId = roomMsgId.uniqueId;
  final messages = ref.watch(renderableBubbleChatMessagesProvider(roomId));
  final index = messages.indexOf(eventId);
  if (index == -1) return null;
  if (index == 0) return null;
  return ref.watch(
    chatRoomMessageProvider((roomId: roomId, uniqueId: messages[index - 1])),
  );
});

final isLastMessageBySenderProvider = Provider.family<bool, RoomMsgId>((
  ref,
  roomMsgId,
) {
  final nextMsg = ref.watch(_getPreviousMessageProvider(roomMsgId));
  if (nextMsg == null) return true;
  final currentMsg = ref.watch(chatRoomMessageProvider(roomMsgId));
  return currentMsg?.eventItem()?.sender() != nextMsg.eventItem()?.sender();
});

final isFirstMessageBySenderProvider = Provider.family<bool, RoomMsgId>((
  ref,
  roomMsgId,
) {
  final prevMsg = ref.watch(_getNextMessageProvider(roomMsgId));
  if (prevMsg == null) return true;
  final currentMsg = ref.watch(chatRoomMessageProvider(roomMsgId));
  return currentMsg?.eventItem()?.sender() != prevMsg.eventItem()?.sender();
});

final isLastMessageProvider = Provider.family<bool, RoomMsgId>((
  ref,
  roomMsgId,
) {
  final messages = ref.watch(renderableChatMessagesProvider(roomMsgId.roomId));
  return messages.last == roomMsgId.uniqueId;
});

/// Provider to fetch user mentions
final userMentionSuggestionsProvider =
    StateProvider.family<Map<String, String>?, String>((ref, roomId) {
      final userId = ref.watch(myUserIdStrProvider);
      final members = ref.watch(membersIdsProvider(roomId)).valueOrNull;
      if (members == null) {
        return {};
      }
      return members.fold<Map<String, String>>({}, (map, uId) {
        if (uId != userId) {
          final displayName = ref.watch(
            memberDisplayNameProvider((roomId: roomId, userId: uId)),
          );
          map[uId] = displayName.valueOrNull ?? '';
        }
        return map;
      });
    });

/// Provider to fetch room mentions
final roomMentionsSuggestionsProvider =
    StateProvider.family<Map<String, String>?, String>((ref, roomId) {
      final rooms = ref.watch(chatIdsProvider);
      return rooms.fold<Map<String, String>>({}, (map, roomId) {
        if (roomId == roomId) return map;

        final displayName = ref.watch(roomDisplayNameProvider(roomId));
        map[roomId] = displayName.valueOrNull ?? '';
        return map;
      });
    });

/// High Level Provider to fetch user/room mentions
final mentionSuggestionsProvider =
    StateProvider.family<Map<String, String>?, (String, MentionType)>((
      ref,
      params,
    ) {
      final (roomId, mentionType) = params;
      return switch (mentionType) {
        MentionType.user => ref.watch(userMentionSuggestionsProvider(roomId)),
        MentionType.room => ref.watch(roomMentionsSuggestionsProvider(roomId)),
      };
    });

final repliedToMsgProvider = AsyncNotifierProvider.autoDispose
    .family<RepliedToMessageNotifier, RepliedToMsgState, RoomMsgId>(() {
      return RepliedToMessageNotifier();
    });

final messageReactionsProvider = StateProvider.autoDispose
    .family<List<ReactionItem>, TimelineEventItem>((ref, item) {
      List<ReactionItem> reactions = [];

      final reactionKeys = asDartStringList(item.reactionKeys());
      for (final key in reactionKeys) {
        final records = item.reactionRecords(key);
        if (records != null) {
          reactions.add((key, records.toList()));
        }
      }

      return reactions;
    });

final chatEditorStateProvider =
    NotifierProvider.autoDispose<ChatEditorNotifier, ChatEditorState>(
      () => ChatEditorNotifier(),
    );
