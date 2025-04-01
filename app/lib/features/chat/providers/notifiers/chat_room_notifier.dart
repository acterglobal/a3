import 'dart:async';
import 'dart:convert';

import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/models/chat_room_state/chat_room_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::chat::room_notifier');

class PostProcessItem {
  final types.Message message;
  final TimelineItem event;

  const PostProcessItem(this.event, this.message);
}

class ChatRoomNotifier extends StateNotifier<ChatRoomState> {
  final Ref ref;
  final String roomId;
  late TimelineStream timeline;
  late Stream<TimelineItemDiff> _listener;
  late StreamSubscription<TimelineItemDiff> _poller;

  ChatRoomNotifier({required this.roomId, required this.ref})
    : super(const ChatRoomState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      timeline = await ref.read(timelineStreamProvider(roomId).future);
      _listener = timeline.messagesStream(); // keep it resident in memory
      _poller = _listener.listen(
        handleDiff,
        onError: (e, s) {
          _log.severe('msg stream errored', e, s);
        },
        onDone: () {
          _log.info('msg stream ended');
        },
      );
      ref.onDispose(() => _poller.cancel());
      do {
        await loadMore(failOnError: true);
        await Future.delayed(const Duration(milliseconds: 200), () => null);
      } while (state.hasMore && state.messages.where(msgFilter).length < 10);
    } catch (e, s) {
      _log.severe('Error loading more messages', e, s);
      state = state.copyWith(loading: ChatRoomLoadingState.error(e.toString()));
    }
  }

  Future<void> loadMore({bool failOnError = false}) async {
    if (state.hasMore && !state.loading.isLoading) {
      try {
        state = state.copyWith(loading: const ChatRoomLoadingState.loading());
        final hasMore = !await timeline.paginateBackwards(20);
        // wait for diffRx to be finished
        state = state.copyWith(
          hasMore: hasMore,
          loading: const ChatRoomLoadingState.loaded(),
        );
      } catch (e, s) {
        _log.severe('Error loading more messages', e, s);
        state = state.copyWith(
          loading: ChatRoomLoadingState.error(e.toString()),
        );
        if (failOnError) {
          rethrow;
        }
      }
    }
  }

  List<types.Message> messagesCopy() =>
      List.from(state.messages, growable: true);

  // Messages CRUD
  void setMessages(List<types.Message> messages) =>
      state = state.copyWith(messages: messages);

  void insertMessage(int to, types.Message m) {
    final newState = messagesCopy();
    if (to < newState.length) {
      newState.insert(to, m);
    } else {
      newState.add(m);
    }
    state = state.copyWith(messages: newState);
  }

  void replaceMessageAt(int index, types.Message m) {
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      final newState = messagesCopy();
      newState[index] = m;
      state = state.copyWith(messages: newState);
    });
  }

  void removeMessage(int idx) {
    final newState = messagesCopy();
    newState.removeAt(idx);
    state = state.copyWith(messages: newState);
  }

  void resetMessages() => state = state.copyWith(messages: []);

  // get the repliedTo field from metadata
  String? getRepliedTo(types.Message message) {
    return message.metadata?['repliedTo'];
  }

  // parses `TimelineItem` event to `types.Message` and updates messages list
  Future<void> handleDiff(TimelineItemDiff diff) async {
    List<PostProcessItem> postProcessing = [];
    switch (diff.action()) {
      case 'Append':
        final values = diff.values();
        if (values == null) {
          _log.severe('On append action, values should be available');
          return;
        }
        List<TimelineItem> messages = values.toList();
        List<types.Message> messagesToAdd = [];
        for (final m in messages) {
          final message = parseMessage(m);
          messagesToAdd.add(message);
          postProcessing.add(PostProcessItem(m, message));
        }
        if (messagesToAdd.isNotEmpty) {
          final newList = messagesCopy();
          newList.addAll(messagesToAdd);
          setMessages(newList);
        }
        break;
      case 'Set': // used to update UnableToDecrypt message
        final value = diff.value();
        if (value == null) {
          _log.severe('On set action, value should be available');
          return;
        }
        final index = diff.index();
        if (index == null) {
          _log.severe('On set action, index should be available');
          return;
        }
        final message = parseMessage(value);
        replaceMessageAt(index, message);
        postProcessing.add(PostProcessItem(value, message));
        break;
      case 'Insert':
        final value = diff.value();
        if (value == null) {
          _log.severe('On insert action, value should be available');
          return;
        }
        final index = diff.index();
        if (index == null) {
          _log.severe('On insert action, index should be available');
          return;
        }
        final message = parseMessage(value);
        insertMessage(index, message);
        postProcessing.add(PostProcessItem(value, message));
        break;
      case 'Remove':
        final index = diff.index();
        if (index == null) {
          _log.severe('On remove action, index should be available');
          return;
        }
        removeMessage(index);
        break;
      case 'PushBack':
        final value = diff.value();
        if (value == null) {
          _log.severe('On push back action, value should be available');
          return;
        }
        final message = parseMessage(value);
        final newList = messagesCopy();
        newList.add(message);
        setMessages(newList);
        postProcessing.add(PostProcessItem(value, message));
        break;
      case 'PushFront':
        final value = diff.value();
        if (value == null) {
          _log.severe('On push front action, value should be available');
          return;
        }
        final message = parseMessage(value);
        insertMessage(0, message);
        postProcessing.add(PostProcessItem(value, message));
        break;
      case 'PopBack':
        final newList = messagesCopy();
        newList.removeLast();
        setMessages(newList);
        break;
      case 'PopFront':
        final newList = messagesCopy();
        newList.removeAt(0);
        setMessages(newList);
        break;
      case 'Clear':
        setMessages([]);
        break;
      case 'Reset':
        final values = diff.values();
        if (values == null) {
          _log.severe('On reset action, values should be available');
          return;
        }
        List<types.Message> newList = [];
        for (final m in values.toList()) {
          final message = parseMessage(m);
          newList.add(message);
          postProcessing.add(PostProcessItem(m, message));
        }
        if (newList.isNotEmpty) {
          setMessages(newList);
        }
        break;
      case 'Truncate':
        final index = diff.index();
        if (index == null) {
          _log.severe('On truncate action, index should be available');
          return;
        }
        final newList = messagesCopy();
        setMessages(newList.take(index).toList());
        break;
      default:
        break;
    }

    // ensure we are done with the state list to avoid
    // races between the async tasks and the diff
    if (postProcessing.isNotEmpty) {
      for (final p in postProcessing) {
        final message = p.message;
        final m = p.event;
        final repliedTo = getRepliedTo(message);
        if (repliedTo != null) {
          await fetchOriginalContent(repliedTo, message.id);
        }
        TimelineEventItem? eventItem = m.eventItem();
        final remoteId = message.remoteId;
        if (eventItem != null && remoteId != null) {
          await fetchMediaBinary(eventItem.msgType(), remoteId, message.id);
        }
      }
    }
  }

  // fetch original content media for reply msg, i.e. text/image/file etc.
  Future<void> fetchOriginalContent(String originalId, String msgId) async {
    TimelineItem roomMsg;
    try {
      roomMsg = await timeline.getMessage(originalId);
    } catch (e, s) {
      _log.severe('Failing to load reference $msgId (from $originalId)', e, s);
      return;
    }

    // reply is allowed for only EventItem not VirtualItem
    // user should be able to get original event as TimelineItem
    TimelineEventItem orgEventItem = roomMsg.eventItem().expect(
      'room msg should have event item',
    );
    EventSendState? eventState = orgEventItem.sendState();
    String eventType = orgEventItem.eventType();
    Map<String, dynamic> repliedToContent = {'eventState': eventState};
    types.Message? repliedTo;
    switch (eventType) {
      case 'm.policy.rule.room':
      case 'm.policy.rule.server':
      case 'm.policy.rule.user':
      case 'm.room.aliases':
      case 'm.room.avatar':
      case 'm.room.canonical_alias':
      case 'm.room.create':
      case 'm.room.encryption':
      case 'm.room.guest_access':
      case 'm.room.history_visibility':
      case 'm.room.join_rules':
      case 'm.room.name':
      case 'm.room.pinned_events':
      case 'm.room.power_levels':
      case 'm.room.server_acl':
      case 'm.room.third_party_invite':
      case 'm.room.tombstone':
      case 'm.room.topic':
      case 'm.space.child':
      case 'm.space.parent':
        break;
      case 'm.room.encrypted':
        repliedTo = types.CustomMessage(
          author: types.User(id: orgEventItem.sender()),
          createdAt: orgEventItem.originServerTs(),
          id: roomMsg.uniqueId(),
          metadata: {'itemType': 'event', 'eventType': eventType},
        );
        break;
      case 'm.room.redaction':
        repliedTo = types.CustomMessage(
          author: types.User(id: orgEventItem.sender()),
          createdAt: orgEventItem.originServerTs(),
          id: roomMsg.uniqueId(),
          metadata: {'itemType': 'event', 'eventType': eventType},
        );
        break;
      case 'm.call.answer':
      case 'm.call.candidates':
      case 'm.call.hangup':
      case 'm.call.invite':
        break;
      case 'm.room.message':
        String? orgMsgType = orgEventItem.msgType();
        switch (orgMsgType) {
          case 'm.text':
            MsgContent? msgContent = orgEventItem.message();
            if (msgContent != null) {
              String body = msgContent.body();
              repliedToContent = {
                'content': body,
                'messageLength': body.length,
              };
              repliedTo = types.TextMessage(
                author: types.User(id: orgEventItem.sender()),
                id: originalId,
                createdAt: orgEventItem.originServerTs(),
                text: body,
                metadata: repliedToContent,
              );
            }
            break;
          case 'm.image':
            MsgContent? msgContent = orgEventItem.message();
            if (msgContent != null) {
              final convo = await ref.read(chatProvider(roomId).future);
              if (convo == null) {
                throw RoomNotFound();
              }
              convo.mediaBinary(originalId, null).then((data) {
                repliedToContent['base64'] = base64Encode(data.asTypedList());
              });
              final source = msgContent.source().expect(
                'msg content of m.image should have media source',
              );
              repliedTo = types.ImageMessage(
                author: types.User(id: orgEventItem.sender()),
                id: originalId,
                createdAt: orgEventItem.originServerTs(),
                name: msgContent.body(),
                size: msgContent.size() ?? 0,
                uri: source.url(),
                width: msgContent.width()?.toDouble() ?? 0,
                metadata: repliedToContent,
              );
            }
            break;
          case 'm.audio':
            MsgContent? msgContent = orgEventItem.message();
            if (msgContent != null) {
              final convo = await ref.read(chatProvider(roomId).future);
              if (convo == null) {
                throw RoomNotFound();
              }
              convo.mediaBinary(originalId, null).then((data) {
                repliedToContent['content'] = base64Encode(data.asTypedList());
              });
              final source = msgContent.source().expect(
                'msg content of m.audio should have media source',
              );
              repliedTo = types.AudioMessage(
                author: types.User(id: orgEventItem.sender()),
                id: originalId,
                createdAt: orgEventItem.originServerTs(),
                name: msgContent.body(),
                duration: Duration(seconds: msgContent.duration() ?? 0),
                size: msgContent.size() ?? 0,
                uri: source.url(),
                metadata: repliedToContent,
              );
            }
            break;
          case 'm.video':
            MsgContent? msgContent = orgEventItem.message();
            if (msgContent != null) {
              final convo = await ref.read(chatProvider(roomId).future);
              if (convo == null) {
                throw RoomNotFound();
              }
              convo.mediaBinary(originalId, null).then((data) {
                repliedToContent['content'] = base64Encode(data.asTypedList());
              });
              final source = msgContent.source().expect(
                'msg content of m.video should have media source',
              );
              repliedTo = types.VideoMessage(
                author: types.User(id: orgEventItem.sender()),
                id: originalId,
                createdAt: orgEventItem.originServerTs(),
                name: msgContent.body(),
                size: msgContent.size() ?? 0,
                uri: source.url(),
                metadata: repliedToContent,
              );
            }
            break;
          case 'm.file':
            MsgContent? msgContent = orgEventItem.message();
            if (msgContent != null) {
              repliedToContent = {'content': msgContent.body()};
              final source = msgContent.source().expect(
                'msg content of m.file should have media source',
              );
              repliedTo = types.FileMessage(
                author: types.User(id: orgEventItem.sender()),
                id: originalId,
                createdAt: orgEventItem.originServerTs(),
                name: msgContent.body(),
                size: msgContent.size() ?? 0,
                uri: source.url(),
                metadata: repliedToContent,
              );
            }
            break;
          case 'm.sticker':
            // user can’t do any action about sticker message
            break;
        }
    }

    final messages = state.messages;
    int index = messages.indexWhere((x) => x.id == msgId);
    if (index != -1 && repliedTo != null) {
      replaceMessageAt(
        index,
        messages[index].copyWith(repliedMessage: repliedTo),
      );
    }
  }

  // maps [TimelineItem] to [types.Message].
  types.Message parseMessage(TimelineItem item) {
    TimelineVirtualItem? virtualItem = item.virtualItem();
    if (virtualItem != null) {
      switch (virtualItem.eventType()) {
        case 'ReadMarker':
          return const types.SystemMessage(
            metadata: {'type': '_read_marker'},
            id: 'read-marker',
            text: 'read-until-here',
          );
        // should not return null, before we can keep track of index in diff receiver
        default:
          return types.UnsupportedMessage(
            author: const types.User(id: 'virtual'),
            id: UniqueKey().toString(),
            metadata: {
              'itemType': 'virtual',
              'eventType': virtualItem.eventType(),
            },
          );
      }
    }

    // If not virtual item, it should be event item
    TimelineEventItem eventItem = item.eventItem().expect(
      'room msg should have event item',
    );
    EventSendState? eventState;
    if (eventItem.sendState() != null) {
      eventState = eventItem.sendState();
    }

    String eventType = eventItem.eventType();
    String sender = eventItem.sender();
    bool isEditable = eventItem.isEditable();
    bool wasEdited = eventItem.wasEdited();
    final author = types.User(id: sender, firstName: simplifyUserId(sender));
    int createdAt = eventItem.originServerTs(); // in milliseconds
    String uniqueId = item.uniqueId();
    String? eventId = eventItem.eventId();

    String? inReplyTo = eventItem.inReplyTo();

    // user read receipts for timeline event item
    Map<String, int> receipts = {};
    for (final userId in asDartStringList(eventItem.readUsers())) {
      final ts = eventItem.receiptTs(userId);
      if (ts != null) receipts[userId] = ts;
    }

    // state event
    switch (eventType) {
      case 'm.policy.rule.room':
        Map<String, dynamic> metadata = {
          'itemType': 'event',
          'eventType': eventType,
          'eventState': eventItem.sendState(),
          'receipts': receipts,
        };
        Map<String, dynamic> state = getPolicyRuleRoom(eventItem);
        if (state.isNotEmpty) {
          metadata['state'] = state;
        }
        return types.CustomMessage(
          author: author,
          createdAt: createdAt,
          id: uniqueId,
          remoteId: eventId,
          metadata: metadata,
        );
      case 'm.policy.rule.server':
        Map<String, dynamic> metadata = {
          'itemType': 'event',
          'eventType': eventType,
          'eventState': eventItem.sendState(),
          'receipts': receipts,
        };
        Map<String, dynamic> state = getPolicyRuleServer(eventItem);
        if (state.isNotEmpty) {
          metadata['state'] = state;
        }
        return types.CustomMessage(
          author: author,
          createdAt: createdAt,
          id: uniqueId,
          remoteId: eventId,
          metadata: metadata,
        );
      case 'm.policy.rule.user':
        Map<String, dynamic> metadata = {
          'itemType': 'event',
          'eventType': eventType,
          'eventState': eventItem.sendState(),
          'receipts': receipts,
        };
        Map<String, dynamic> state = getPolicyRuleUser(eventItem);
        if (state.isNotEmpty) {
          metadata['state'] = state;
        }
        return types.CustomMessage(
          author: author,
          createdAt: createdAt,
          id: uniqueId,
          remoteId: eventId,
          metadata: metadata,
        );
      case 'm.room.aliases':
        Map<String, dynamic> metadata = {
          'itemType': 'event',
          'eventType': eventType,
          'eventState': eventItem.sendState(),
          'receipts': receipts,
        };
        Map<String, dynamic> state = getRoomAliases(eventItem);
        if (state.isNotEmpty) {
          metadata['state'] = state;
        }
        return types.CustomMessage(
          author: author,
          createdAt: createdAt,
          id: uniqueId,
          remoteId: eventId,
          metadata: metadata,
        );
      case 'm.room.avatar':
        Map<String, dynamic> metadata = {
          'itemType': 'event',
          'eventType': eventType,
          'eventState': eventItem.sendState(),
          'receipts': receipts,
        };
        Map<String, dynamic> state = getRoomAvatar(eventItem);
        if (state.isNotEmpty) {
          metadata['state'] = state;
        }
        return types.CustomMessage(
          author: author,
          createdAt: createdAt,
          id: uniqueId,
          remoteId: eventId,
          metadata: metadata,
        );
      case 'm.room.canonical_alias':
        Map<String, dynamic> metadata = {
          'itemType': 'event',
          'eventType': eventType,
          'eventState': eventItem.sendState(),
          'receipts': receipts,
        };
        Map<String, dynamic> state = getRoomCanonicalAlias(eventItem);
        if (state.isNotEmpty) {
          metadata['state'] = state;
        }
        return types.CustomMessage(
          author: author,
          createdAt: createdAt,
          id: uniqueId,
          remoteId: eventId,
          metadata: metadata,
        );
      case 'm.room.create':
        return types.CustomMessage(
          author: author,
          createdAt: createdAt,
          id: uniqueId,
          remoteId: eventId,
          metadata: {
            'itemType': 'event',
            'eventType': eventType,
            'eventState': eventItem.sendState(),
            'receipts': receipts,
          },
        );
      case 'm.room.encryption':
        Map<String, dynamic> metadata = {
          'itemType': 'event',
          'eventType': eventType,
          'eventState': eventItem.sendState(),
          'receipts': receipts,
        };
        Map<String, dynamic> state = getRoomEncryption(eventItem);
        if (state.isNotEmpty) {
          metadata['state'] = state;
        }
        return types.CustomMessage(
          author: author,
          createdAt: createdAt,
          id: uniqueId,
          remoteId: eventId,
          metadata: metadata,
        );
      case 'm.room.guest_access':
        Map<String, dynamic> metadata = {
          'itemType': 'event',
          'eventType': eventType,
          'eventState': eventItem.sendState(),
          'receipts': receipts,
        };
        Map<String, dynamic> state = getRoomGuestAccess(eventItem);
        if (state.isNotEmpty) {
          metadata['state'] = state;
        }
        return types.CustomMessage(
          author: author,
          createdAt: createdAt,
          id: uniqueId,
          remoteId: eventId,
          metadata: metadata,
        );
      case 'm.room.history_visibility':
        Map<String, dynamic> metadata = {
          'itemType': 'event',
          'eventType': eventType,
          'eventState': eventItem.sendState(),
          'receipts': receipts,
        };
        Map<String, dynamic> state = getRoomHistoryVisibility(eventItem);
        if (state.isNotEmpty) {
          metadata['state'] = state;
        }
        return types.CustomMessage(
          author: author,
          createdAt: createdAt,
          id: uniqueId,
          remoteId: eventId,
          metadata: metadata,
        );
      case 'm.room.join_rules':
        Map<String, dynamic> metadata = {
          'itemType': 'event',
          'eventType': eventType,
          'eventState': eventItem.sendState(),
          'receipts': receipts,
        };
        Map<String, dynamic> state = getRoomJoinRules(eventItem);
        if (state.isNotEmpty) {
          metadata['state'] = state;
        }
        return types.CustomMessage(
          author: author,
          createdAt: createdAt,
          id: uniqueId,
          remoteId: eventId,
          metadata: metadata,
        );
      case 'm.room.name':
        Map<String, dynamic> metadata = {
          'itemType': 'event',
          'eventType': eventType,
          'eventState': eventItem.sendState(),
          'receipts': receipts,
        };
        Map<String, dynamic> state = getRoomName(eventItem);
        if (state.isNotEmpty) {
          metadata['state'] = state;
        }
        return types.CustomMessage(
          author: author,
          createdAt: createdAt,
          id: uniqueId,
          remoteId: eventId,
          metadata: metadata,
        );
      case 'm.room.pinned_events':
        Map<String, dynamic> metadata = {
          'itemType': 'event',
          'eventType': eventType,
          'eventState': eventItem.sendState(),
          'receipts': receipts,
        };
        Map<String, dynamic> state = getRoomPinnedEvents(eventItem);
        if (state.isNotEmpty) {
          metadata['state'] = state;
        }
        return types.CustomMessage(
          author: author,
          createdAt: createdAt,
          id: uniqueId,
          remoteId: eventId,
          metadata: metadata,
        );
      case 'm.room.power_levels':
        Map<String, dynamic> metadata = {
          'itemType': 'event',
          'eventType': eventType,
          'eventState': eventItem.sendState(),
          'receipts': receipts,
        };
        Map<String, dynamic> state = getRoomPowerLevels(eventItem);
        if (state.isNotEmpty) {
          metadata['state'] = state;
        }
        return types.CustomMessage(
          author: author,
          createdAt: createdAt,
          id: uniqueId,
          remoteId: eventId,
          metadata: metadata,
        );
      case 'm.room.server_acl':
        Map<String, dynamic> metadata = {
          'itemType': 'event',
          'eventType': eventType,
          'eventState': eventItem.sendState(),
          'receipts': receipts,
        };
        Map<String, dynamic> state = getRoomServerAcl(eventItem);
        if (state.isNotEmpty) {
          metadata['state'] = state;
        }
        return types.CustomMessage(
          author: author,
          createdAt: createdAt,
          id: uniqueId,
          remoteId: eventId,
          metadata: metadata,
        );
      case 'm.room.third_party_invite':
        Map<String, dynamic> metadata = {
          'itemType': 'event',
          'eventType': eventType,
          'eventState': eventItem.sendState(),
          'receipts': receipts,
        };
        Map<String, dynamic> state = getRoomThirdPartyInvite(eventItem);
        if (state.isNotEmpty) {
          metadata['state'] = state;
        }
        return types.CustomMessage(
          author: author,
          createdAt: createdAt,
          id: uniqueId,
          remoteId: eventId,
          metadata: metadata,
        );
      case 'm.room.tombstone':
        Map<String, dynamic> metadata = {
          'itemType': 'event',
          'eventType': eventType,
          'eventState': eventItem.sendState(),
          'receipts': receipts,
        };
        Map<String, dynamic> state = getRoomTombstone(eventItem);
        if (state.isNotEmpty) {
          metadata['state'] = state;
        }
        return types.CustomMessage(
          author: author,
          createdAt: createdAt,
          id: uniqueId,
          remoteId: eventId,
          metadata: metadata,
        );
      case 'm.room.topic':
        Map<String, dynamic> metadata = {
          'itemType': 'event',
          'eventType': eventType,
          'eventState': eventItem.sendState(),
          'receipts': receipts,
        };
        Map<String, dynamic> state = getRoomTopic(eventItem);
        if (state.isNotEmpty) {
          metadata['state'] = state;
        }
        return types.CustomMessage(
          author: author,
          createdAt: createdAt,
          id: uniqueId,
          remoteId: eventId,
          metadata: metadata,
        );
      case 'm.space.child':
        Map<String, dynamic> metadata = {
          'itemType': 'event',
          'eventType': eventType,
          'eventState': eventItem.sendState(),
          'receipts': receipts,
        };
        Map<String, dynamic> state = getSpaceChild(eventItem);
        if (state.isNotEmpty) {
          metadata['state'] = state;
        }
        return types.CustomMessage(
          author: author,
          createdAt: createdAt,
          id: uniqueId,
          remoteId: eventId,
          metadata: metadata,
        );
      case 'm.space.parent':
        Map<String, dynamic> metadata = {
          'itemType': 'event',
          'eventType': eventType,
          'eventState': eventItem.sendState(),
          'receipts': receipts,
        };
        Map<String, dynamic> state = getSpaceParent(eventItem);
        if (state.isNotEmpty) {
          metadata['state'] = state;
        }
        return types.CustomMessage(
          author: author,
          createdAt: createdAt,
          id: uniqueId,
          remoteId: eventId,
          metadata: metadata,
        );
      case 'profileChange': // some of m.room.member
        ProfileChange? change = eventItem.profileChange();
        if (change == null) {
          return types.UnsupportedMessage(
            author: const types.User(id: 'virtual'),
            remoteId: eventId,
            id: UniqueKey().toString(),
            metadata: const {'itemType': 'virtual'},
          );
        }
        Map<String, dynamic> metadata = {
          'itemType': 'event',
          'eventType': eventType,
          'userId': change.userId().toString(),
        };
        switch (change.displayNameChange()) {
          case 'Changed':
            metadata['displayName'] = {
              'change': 'Changed',
              'oldVal': change.displayNameOldVal(),
              'newVal': change.displayNameNewVal(),
            };
            break;
          case 'Unset':
            metadata['displayName'] = {
              'change': 'Unset',
              'oldVal': change.displayNameOldVal(),
            };
            break;
          case 'Set':
            metadata['displayName'] = {
              'change': 'Set',
              'newVal': change.displayNameNewVal(),
            };
            break;
        }
        switch (change.avatarUrlChange()) {
          case 'Changed':
            metadata['avatarUrl'] = {
              'change': 'Changed',
              'oldVal': change.avatarUrlOldVal().toString(),
              'newVal': change.avatarUrlNewVal().toString(),
            };
            break;
          case 'Unset':
            metadata['avatarUrl'] = {
              'change': 'Unset',
              'oldVal': change.avatarUrlOldVal().toString(),
            };
            break;
          case 'Set':
            metadata['avatarUrl'] = {
              'change': 'Set',
              'newVal': change.avatarUrlNewVal().toString(),
            };
            break;
        }
        return types.CustomMessage(
          author: author,
          createdAt: createdAt,
          id: uniqueId,
          roomId: roomId,
          remoteId: eventId,
          metadata: metadata,
        );
      case 'membershipChange': // some of m.room.member
        MembershipChange? change = eventItem.membershipChange();
        if (change == null) {
          return types.UnsupportedMessage(
            author: const types.User(id: 'virtual'),
            remoteId: eventId,
            id: UniqueKey().toString(),
            metadata: const {'itemType': 'virtual'},
          );
        }
        return types.CustomMessage(
          author: author,
          createdAt: createdAt,
          id: uniqueId,
          roomId: roomId,
          remoteId: eventId,
          metadata: {
            'itemType': 'event',
            'eventType': eventType,
            'change': change.change(),
            'userId': change.userId().toString(),
            'receipts': receipts,
          },
        );
    }

    // message event
    switch (eventType) {
      case 'm.call.answer':
      case 'm.call.candidates':
      case 'm.call.hangup':
      case 'm.call.invite':
        break;
      case 'm.reaction':
      case 'm.room.encrypted':
        final metadata = {
          'itemType': 'event',
          'eventType': eventType,
          'eventState': eventState,
          'receipts': receipts,
        };
        if (inReplyTo != null) {
          metadata['repliedTo'] = inReplyTo;
        }
        return types.CustomMessage(
          remoteId: eventId,
          author: author,
          createdAt: createdAt,
          id: uniqueId,
          roomId: roomId,
          metadata: metadata,
        );
      case 'm.room.redaction':
        final metadata = {
          'itemType': 'event',
          'eventType': eventType,
          'eventState': eventState,
          'receipts': receipts,
        };
        if (inReplyTo != null) {
          metadata['repliedTo'] = inReplyTo;
        }
        return types.CustomMessage(
          remoteId: eventId,
          author: author,
          createdAt: createdAt,
          id: uniqueId,
          metadata: metadata,
        );
      case 'm.room.message':
        MsgContent? message = eventItem.message();
        if (message == null) break;
        Map<String, dynamic> reactions = {};
        for (final key in asDartStringList(eventItem.reactionKeys())) {
          final records = eventItem.reactionRecords(key);
          if (records != null) reactions[key] = records.toList();
        }
        switch (eventItem.msgType()) {
          case 'm.audio':
            Map<String, dynamic> metadata = {
              'base64': '',
              'eventState': eventState,
              'receipts': receipts,
              'was_edited': wasEdited,
              'isEditable': isEditable,
            };
            if (inReplyTo != null) {
              metadata['repliedTo'] = inReplyTo;
            }
            if (reactions.isNotEmpty) {
              metadata['reactions'] = reactions;
            }
            final source = message.source().expect(
              'msg content of m.audio should have media source',
            );
            return types.AudioMessage(
              author: author,
              createdAt: createdAt,
              remoteId: eventId,
              duration: Duration(seconds: message.duration() ?? 0),
              id: uniqueId,
              metadata: metadata,
              mimeType: message.mimetype(),
              name: message.body(),
              size: message.size() ?? 0,
              uri: source.url(),
            );
          case 'm.emote':
            String? formattedBody = message.formattedBody();
            String body = message.body(); // always exists
            Map<String, dynamic> metadata = {
              'eventState': eventState,
              'receipts': receipts,
              'was_edited': wasEdited,
              'isEditable': isEditable,
              // check whether string only contains emoji(s).
              'enlargeEmoji': isOnlyEmojis(body),
            };
            if (inReplyTo != null) {
              metadata['repliedTo'] = inReplyTo;
            }
            if (reactions.isNotEmpty) {
              metadata['reactions'] = reactions;
            }
            return types.TextMessage(
              author: author,
              remoteId: eventId,
              createdAt: createdAt,
              id: uniqueId,
              metadata: metadata,
              text: formattedBody ?? body,
            );
          case 'm.file':
            Map<String, dynamic> metadata = {
              'eventState': eventState,
              'receipts': receipts,
              'was_edited': wasEdited,
              'isEditable': isEditable,
            };
            if (inReplyTo != null) {
              metadata['repliedTo'] = inReplyTo;
            }
            if (reactions.isNotEmpty) {
              metadata['reactions'] = reactions;
            }
            final source = message.source().expect(
              'msg content of m.file should have media source',
            );
            return types.FileMessage(
              author: author,
              remoteId: eventId,
              createdAt: createdAt,
              id: uniqueId,
              metadata: metadata,
              mimeType: message.mimetype(),
              name: message.body(),
              size: message.size() ?? 0,
              uri: source.url(),
            );
          case 'm.image':
            Map<String, dynamic> metadata = {
              'eventState': eventState,
              'receipts': receipts,
              'was_edited': wasEdited,
              'isEditable': isEditable,
            };
            if (inReplyTo != null) {
              metadata['repliedTo'] = inReplyTo;
            }
            if (reactions.isNotEmpty) {
              metadata['reactions'] = reactions;
            }
            final source = message.source().expect(
              'msg content of m.image should have media source',
            );
            return types.ImageMessage(
              author: author,
              remoteId: eventId,
              createdAt: createdAt,
              height: message.height()?.toDouble(),
              id: uniqueId,
              metadata: metadata,
              name: message.body(),
              size: message.size() ?? 0,
              uri: source.url(),
              width: message.width()?.toDouble(),
            );
          case 'm.location':
            Map<String, dynamic> metadata = {
              'itemType': 'event',
              'eventType': eventType,
              'msgType': 'm.location',
              'body': message.body(),
              'geoUri': message.geoUri(),
              'eventState': eventState,
              'receipts': receipts,
              'was_edited': wasEdited,
              'isEditable': isEditable,
            };
            if (inReplyTo != null) {
              metadata['repliedTo'] = inReplyTo;
            }
            if (reactions.isNotEmpty) {
              metadata['reactions'] = reactions;
            }
            final thumbnailSource = message.thumbnailSource();
            if (thumbnailSource != null) {
              metadata['thumbnailSource'] = thumbnailSource.url();
            }
            final thumbnailInfo = message.thumbnailInfo();
            final mimetype = thumbnailInfo?.mimetype();
            final size = thumbnailInfo?.size();
            final width = thumbnailInfo?.width();
            final height = thumbnailInfo?.height();
            if (mimetype != null) {
              metadata['thumbnailMimetype'] = mimetype;
            }
            if (size != null) {
              metadata['thumbnailSize'] = size;
            }
            if (width != null) {
              metadata['thumbnailWidth'] = width;
            }
            if (height != null) {
              metadata['thumbnailHeight'] = height;
            }
            return types.CustomMessage(
              author: author,
              remoteId: eventId,
              createdAt: createdAt,
              id: uniqueId,
              metadata: metadata,
            );
          case 'm.notice':
          case 'm.server_notice':
          case 'm.text':
            final body = prepareMsg(message);
            Map<String, dynamic> metadata = {
              'eventState': eventState,
              'receipts': receipts,
              'was_edited': wasEdited,
              'isEditable': isEditable,
              // check whether string only contains emoji(s).
              'enlargeEmoji': isOnlyEmojis(body),
            };
            if (inReplyTo != null) {
              metadata['repliedTo'] = inReplyTo;
            }
            if (reactions.isNotEmpty) {
              metadata['reactions'] = reactions;
            }
            return types.TextMessage(
              author: author,
              remoteId: eventId,
              createdAt: createdAt,
              id: uniqueId,
              metadata: metadata,
              text: body,
            );
          case 'm.video':
            Map<String, dynamic> metadata = {
              'base64': '',
              'eventState': eventState,
              'receipts': receipts,
              'was_edited': wasEdited,
              'isEditable': isEditable,
            };
            if (inReplyTo != null) {
              metadata['repliedTo'] = inReplyTo;
            }
            if (reactions.isNotEmpty) {
              metadata['reactions'] = reactions;
            }
            final source = message.source().expect(
              'msg content of m.video should have media source',
            );
            return types.VideoMessage(
              author: author,
              remoteId: eventId,
              createdAt: createdAt,
              id: uniqueId,
              metadata: metadata,
              name: message.body(),
              size: message.size() ?? 0,
              uri: source.url(),
            );
          case 'm.key.verification.request':
            break;
        }
        break;
      case 'm.sticker':
        Map<String, dynamic> receipts = {};
        for (final userId in asDartStringList(eventItem.readUsers())) {
          final ts = eventItem.receiptTs(userId);
          if (ts != null) receipts[userId] = ts;
        }
        Map<String, dynamic> reactions = {};
        for (final key in asDartStringList(eventItem.reactionKeys())) {
          final records = eventItem.reactionRecords(key);
          if (records != null) reactions[key] = records.toList();
        }
        Sticker? sticker = eventItem.sticker();
        if (sticker == null) break;
        Map<String, dynamic> metadata = {
          'itemType': 'event',
          'eventType': eventType,
          'name': sticker.body(),
          'size': sticker.size() ?? 0,
          'width': sticker.width()?.toDouble(),
          'height': sticker.height()?.toDouble(),
          'base64': '',
          'eventState': eventState,
          'receipts': receipts,
          'was_edited': wasEdited,
          'isEditable': isEditable,
        };
        if (inReplyTo != null) {
          metadata['repliedTo'] = inReplyTo;
        }
        if (reactions.isNotEmpty) {
          metadata['reactions'] = reactions;
        }
        return types.CustomMessage(
          author: author,
          remoteId: eventId,
          createdAt: createdAt,
          id: uniqueId,
          metadata: metadata,
        );
      case 'm.poll.start':
        PollContent? poll = eventItem.poll();
        if (poll == null) break;
        return types.CustomMessage(
          author: author,
          remoteId: eventId,
          createdAt: createdAt,
          id: uniqueId,
          metadata: {
            'itemType': 'event',
            'eventType': eventType,
            'msgType': eventItem.msgType(),
            'body': poll.fallbackText(),
            'was_edited': wasEdited,
            'isEditable': isEditable,
            'eventState': eventState,
            'receipts': receipts,
          },
        );
    }
    return types.UnsupportedMessage(
      author: const types.User(id: 'virtual'),
      remoteId: eventId,
      id: UniqueKey().toString(),
      metadata: const {'itemType': 'virtual'},
    );
  }

  Map<String, dynamic> getPolicyRuleRoom(TimelineEventItem eventItem) {
    PolicyRuleRoomContent content = eventItem.policyRuleRoom().expect(
      'failed to get content of m.policy.rule.room',
    );
    Map<String, dynamic> result = {};
    String? entityChange = content.entityChange();
    if (entityChange != null) {
      final entity = {'change': entityChange, 'new': content.entityNewVal()};
      String? oldVal = content.entityOldVal();
      if (oldVal != null) entity['old'] = oldVal;
      result['entity'] = entity;
    }
    String? reasonChange = content.reasonChange();
    if (reasonChange != null) {
      final reason = {'change': reasonChange, 'new': content.reasonNewVal()};
      String? oldVal = content.reasonOldVal();
      if (oldVal != null) reason['old'] = oldVal;
      result['reason'] = reason;
    }
    String? recommendationChange = content.recommendationChange();
    if (recommendationChange != null) {
      final recommendation = {
        'change': recommendationChange,
        'new': content.recommendationNewVal(),
      };
      String? oldVal = content.recommendationOldVal();
      if (oldVal != null) recommendation['old'] = oldVal;
      result['recommendation'] = recommendation;
    }
    return result;
  }

  Map<String, dynamic> getPolicyRuleServer(TimelineEventItem eventItem) {
    PolicyRuleServerContent content = eventItem.policyRuleServer().expect(
      'failed to get content of m.policy.rule.server',
    );
    Map<String, dynamic> result = {};
    String? entityChange = content.entityChange();
    if (entityChange != null) {
      final entity = {'change': entityChange, 'new': content.entityNewVal()};
      String? oldVal = content.entityOldVal();
      if (oldVal != null) entity['old'] = oldVal;
      result['entity'] = entity;
    }
    String? reasonChange = content.reasonChange();
    if (reasonChange != null) {
      final reason = {'change': reasonChange, 'new': content.reasonNewVal()};
      String? oldVal = content.reasonOldVal();
      if (oldVal != null) reason['old'] = oldVal;
      result['reason'] = reason;
    }
    String? recommendationChange = content.recommendationChange();
    if (recommendationChange != null) {
      final recommendation = {
        'change': recommendationChange,
        'new': content.recommendationNewVal(),
      };
      String? oldVal = content.recommendationOldVal();
      if (oldVal != null) recommendation['old'] = oldVal;
      result['recommendation'] = recommendation;
    }
    return result;
  }

  Map<String, dynamic> getPolicyRuleUser(TimelineEventItem eventItem) {
    PolicyRuleUserContent content = eventItem.policyRuleUser().expect(
      'failed to get content of m.policy.rule.user',
    );
    Map<String, dynamic> result = {};
    String? entityChange = content.entityChange();
    if (entityChange != null) {
      final entity = {'change': entityChange, 'new': content.entityNewVal()};
      String? oldVal = content.entityOldVal();
      if (oldVal != null) entity['old'] = oldVal;
      result['entity'] = entity;
    }
    String? reasonChange = content.reasonChange();
    if (reasonChange != null) {
      final reason = {'change': reasonChange, 'new': content.reasonNewVal()};
      String? oldVal = content.reasonOldVal();
      if (oldVal != null) reason['old'] = oldVal;
      result['reason'] = reason;
    }
    String? recommendationChange = content.recommendationChange();
    if (recommendationChange != null) {
      final recommendation = {
        'change': recommendationChange,
        'new': content.recommendationNewVal(),
      };
      String? oldVal = content.recommendationOldVal();
      if (oldVal != null) recommendation['old'] = oldVal;
      result['recommendation'] = recommendation;
    }
    return result;
  }

  Map<String, dynamic> getRoomAliases(TimelineEventItem eventItem) {
    RoomAliasesContent content = eventItem.roomAliases().expect(
      'failed to get content of m.room.aliases',
    );
    Map<String, dynamic> result = {};
    String? change = content.change();
    if (change != null) {
      result['change'] = change;
      result['new'] = content.newVal().toDart();
      FfiListFfiString? oldVal = content.oldVal();
      if (oldVal != null) result['old'] = oldVal.toDart();
    }
    return result;
  }

  Map<String, dynamic> getRoomAvatar(TimelineEventItem eventItem) {
    RoomAvatarContent content = eventItem.roomAvatar().expect(
      'failed to get content of m.room.avatar',
    );
    Map<String, dynamic> result = {};
    String? urlChange = content.urlChange();
    if (urlChange != null) {
      final url = {'change': urlChange};
      String? newVal = content.urlNewVal();
      if (newVal != null) url['new'] = newVal;
      String? oldVal = content.urlOldVal();
      if (oldVal != null) url['old'] = oldVal;
      result['url'] = url;
    }
    return result;
  }

  Map<String, dynamic> getRoomCanonicalAlias(TimelineEventItem eventItem) {
    RoomCanonicalAliasContent content = eventItem.roomCanonicalAlias().expect(
      'failed to get content of m.room.canonical_alias',
    );
    Map<String, dynamic> result = {};
    String? aliasChange = content.aliasChange();
    if (aliasChange != null) {
      final alias = {'change': aliasChange};
      String? newVal = content.aliasNewVal();
      if (newVal != null) alias['new'] = newVal;
      String? oldVal = content.aliasOldVal();
      if (oldVal != null) alias['old'] = oldVal;
      result['alias'] = alias;
    }
    String? altAliasesChange = content.altAliasesChange();
    if (altAliasesChange != null) {
      Map<String, dynamic> altAliases = {
        'change': altAliasesChange,
        'new': content.altAliasesNewVal().toDart(),
      };
      FfiListFfiString? oldVal = content.altAliasesOldVal();
      if (oldVal != null) altAliases['old'] = oldVal.toDart();
      result['altAliases'] = altAliases;
    }
    return result;
  }

  Map<String, dynamic> getRoomEncryption(TimelineEventItem eventItem) {
    RoomEncryptionContent content = eventItem.roomEncryption().expect(
      'failed to get content of m.room.encryption',
    );
    Map<String, dynamic> result = {};
    String? algorithmChange = content.algorithmChange();
    if (algorithmChange != null) {
      final algorithm = {
        'change': algorithmChange,
        'new': content.algorithmNewVal(),
      };
      String? oldVal = content.algorithmOldVal();
      if (oldVal != null) algorithm['old'] = oldVal;
      result['algorithm'] = algorithm;
    }
    return result;
  }

  Map<String, dynamic> getRoomGuestAccess(TimelineEventItem eventItem) {
    RoomGuestAccessContent content = eventItem.roomGuestAccess().expect(
      'failed to get content of m.room.guest_access',
    );
    Map<String, dynamic> result = {};
    String? change = content.change();
    if (change != null) {
      result['change'] = change;
      result['new'] = content.newVal();
      String? oldVal = content.oldVal();
      if (oldVal != null) result['old'] = oldVal;
    }
    return result;
  }

  Map<String, dynamic> getRoomHistoryVisibility(TimelineEventItem eventItem) {
    RoomHistoryVisibilityContent content = eventItem
        .roomHistoryVisibility()
        .expect('failed to get content of m.room.history_visibility');
    Map<String, dynamic> result = {};
    String? change = content.change();
    if (change != null) {
      result['change'] = change;
      result['new'] = content.newVal();
      String? oldVal = content.oldVal();
      if (oldVal != null) result['old'] = oldVal;
    }
    return result;
  }

  Map<String, dynamic> getRoomJoinRules(TimelineEventItem eventItem) {
    RoomJoinRulesContent content = eventItem.roomJoinRules().expect(
      'failed to get content of m.room.join_rules',
    );
    Map<String, dynamic> result = {};
    String? change = content.change();
    if (change != null) {
      result['change'] = change;
      result['new'] = content.newVal();
      String? oldVal = content.oldVal();
      if (oldVal != null) result['old'] = oldVal;
    }
    return result;
  }

  Map<String, dynamic> getRoomName(TimelineEventItem eventItem) {
    RoomNameContent content = eventItem.roomName().expect(
      'failed to get content of m.room.name',
    );
    Map<String, dynamic> result = {};
    String? change = content.change();
    if (change != null) {
      result['change'] = change;
      result['new'] = content.newVal();
      String? oldVal = content.oldVal();
      if (oldVal != null) result['old'] = oldVal;
    }
    return result;
  }

  Map<String, dynamic> getRoomPinnedEvents(TimelineEventItem eventItem) {
    RoomPinnedEventsContent content = eventItem.roomPinnedEvents().expect(
      'failed to get content of m.room.pinned_events',
    );
    Map<String, dynamic> result = {};
    String? change = content.change();
    if (change != null) {
      result['change'] = change;
      result['new'] = content.newVal().toDart();
      FfiListFfiString? oldVal = content.oldVal();
      if (oldVal != null) result['old'] = oldVal.toDart();
    }
    return result;
  }

  Map<String, dynamic> getRoomPowerLevels(TimelineEventItem eventItem) {
    RoomPowerLevelsContent content = eventItem.roomPowerLevels().expect(
      'failed to get content of m.room.power_levels',
    );
    Map<String, dynamic> result = {};
    String? banChange = content.banChange();
    if (banChange != null) {
      final ban = {'change': banChange, 'new': content.banNewVal()};
      int? oldVal = content.banOldVal();
      if (oldVal != null) ban['old'] = oldVal;
      result['ban'] = ban;
    }
    String? eventsChange = content.eventsChange();
    if (eventsChange != null) {
      result['events'] = {'change': eventsChange};
    }
    String? inviteChange = content.inviteChange();
    if (inviteChange != null) {
      final invite = {'change': inviteChange, 'new': content.inviteNewVal()};
      int? oldVal = content.inviteOldVal();
      if (oldVal != null) invite['old'] = oldVal;
      result['invite'] = invite;
    }
    String? kickChange = content.kickChange();
    if (kickChange != null) {
      final kick = {'change': kickChange, 'new': content.kickNewVal()};
      int? oldVal = content.kickOldVal();
      if (oldVal != null) kick['old'] = oldVal;
      result['kick'] = kick;
    }
    String? notificationsChange = content.notificationsChange();
    if (notificationsChange != null) {
      final notifications = {
        'change': notificationsChange,
        'new': content.notificationsNewVal(),
      };
      int? oldVal = content.notificationsOldVal();
      if (oldVal != null) notifications['old'] = oldVal;
      result['notifications'] = notifications;
    }
    String? redactChange = content.redactChange();
    if (redactChange != null) {
      final redact = {'change': redactChange, 'new': content.redactNewVal()};
      int? oldVal = content.redactOldVal();
      if (oldVal != null) redact['old'] = oldVal;
      result['redact'] = redact;
    }
    String? stateDefaultChange = content.stateDefaultChange();
    if (stateDefaultChange != null) {
      final stateDefault = {
        'change': stateDefaultChange,
        'new': content.stateDefaultNewVal(),
      };
      int? oldVal = content.stateDefaultOldVal();
      if (oldVal != null) stateDefault['old'] = oldVal;
      result['stateDefault'] = stateDefault;
    }
    String? usersChange = content.usersChange();
    if (usersChange != null) {
      result['users'] = {'change': usersChange};
    }
    String? usersDefaultChange = content.usersDefaultChange();
    if (usersDefaultChange != null) {
      final usersDefault = {
        'change': usersDefaultChange,
        'new': content.usersDefaultNewVal(),
      };
      int? oldVal = content.usersDefaultOldVal();
      if (oldVal != null) usersDefault['old'] = oldVal;
      result['usersDefault'] = usersDefault;
    }
    return result;
  }

  Map<String, dynamic> getRoomServerAcl(TimelineEventItem eventItem) {
    RoomServerAclContent content = eventItem.roomServerAcl().expect(
      'failed to get content of m.room.server_acl',
    );
    Map<String, dynamic> result = {};
    String? allowIpLiteralsChange = content.allowIpLiteralsChange();
    if (allowIpLiteralsChange != null) {
      final allowIpLiterals = {
        'change': allowIpLiteralsChange,
        'new': content.allowIpLiteralsNewVal(),
      };
      bool? oldVal = content.allowIpLiteralsOldVal();
      if (oldVal != null) allowIpLiterals['old'] = oldVal;
      result['allowIpLiterals'] = allowIpLiterals;
    }
    String? allowChange = content.allowChange();
    if (allowChange != null) {
      final allow = {
        'change': allowChange,
        'new': content.allowNewVal().toDart(),
      };
      FfiListFfiString? oldVal = content.allowOldVal();
      if (oldVal != null) allow['old'] = oldVal.toDart();
      result['allow'] = allow;
    }
    String? denyChange = content.denyChange();
    if (denyChange != null) {
      final deny = {'change': denyChange, 'new': content.denyNewVal().toDart()};
      FfiListFfiString? oldVal = content.denyOldVal();
      if (oldVal != null) deny['old'] = oldVal.toDart();
      result['deny'] = deny;
    }
    return result;
  }

  Map<String, dynamic> getRoomThirdPartyInvite(TimelineEventItem eventItem) {
    RoomThirdPartyInviteContent content = eventItem
        .roomThirdPartyInvite()
        .expect('failed to get content of m.room.third_party_invite');
    Map<String, dynamic> result = {};
    String? displayNameChange = content.displayNameChange();
    if (displayNameChange != null) {
      final displayName = {
        'change': displayNameChange,
        'new': content.displayNameNewVal(),
      };
      String? oldVal = content.displayNameOldVal();
      if (oldVal != null) displayName['old'] = oldVal;
      result['displayName'] = displayName;
    }
    String? keyValidityUrlChange = content.keyValidityUrlChange();
    if (keyValidityUrlChange != null) {
      final keyValidityUrl = {
        'change': keyValidityUrlChange,
        'new': content.keyValidityUrlNewVal(),
      };
      String? oldVal = content.keyValidityUrlOldVal();
      if (oldVal != null) keyValidityUrl['old'] = oldVal;
      result['keyValidityUrl'] = keyValidityUrl;
    }
    String? publicKeyChange = content.publicKeyChange();
    if (publicKeyChange != null) {
      result['publicKey'] = {'change': publicKeyChange};
    }
    return result;
  }

  Map<String, dynamic> getRoomTombstone(TimelineEventItem eventItem) {
    RoomTombstoneContent content = eventItem.roomTombstone().expect(
      'failed to get content of m.room.tombstone',
    );
    Map<String, dynamic> result = {};
    String? bodyChange = content.bodyChange();
    if (bodyChange != null) {
      final body = {'change': bodyChange, 'new': content.bodyNewVal()};
      String? oldVal = content.bodyOldVal();
      if (oldVal != null) body['old'] = oldVal;
      result['body'] = body;
    }
    String? replacementRoomChange = content.replacementRoomChange();
    if (replacementRoomChange != null) {
      final replacementRoom = {
        'change': replacementRoomChange,
        'new': content.replacementRoomNewVal(),
      };
      String? oldVal = content.replacementRoomOldVal();
      if (oldVal != null) replacementRoom['old'] = oldVal;
      result['replacementRoom'] = replacementRoom;
    }
    return result;
  }

  Map<String, dynamic> getRoomTopic(TimelineEventItem eventItem) {
    RoomTopicContent content = eventItem.roomTopic().expect(
      'failed to get content of m.room.topic',
    );
    Map<String, dynamic> result = {};
    String? change = content.change();
    if (change != null) {
      result['change'] = change;
      result['new'] = content.newVal();
      String? oldVal = content.oldVal();
      if (oldVal != null) result['old'] = oldVal;
    }
    return result;
  }

  Map<String, dynamic> getSpaceChild(TimelineEventItem eventItem) {
    SpaceChildContent content = eventItem.spaceChild().expect(
      'failed to get content of m.space.child',
    );
    Map<String, dynamic> result = {};
    String? viaChange = content.viaChange();
    if (viaChange != null) {
      final via = {'change': viaChange, 'new': content.viaNewVal().toDart()};
      FfiListFfiString? oldVal = content.viaOldVal();
      if (oldVal != null) via['old'] = oldVal.toDart();
      result['via'] = via;
    }
    String? orderChange = content.orderChange();
    if (orderChange != null) {
      final order = {'change': orderChange};
      String? newVal = content.orderNewVal();
      if (newVal != null) order['old'] = newVal;
      String? oldVal = content.orderOldVal();
      if (oldVal != null) order['old'] = oldVal;
      result['order'] = order;
    }
    String? suggestedChange = content.suggestedChange();
    if (suggestedChange != null) {
      final suggested = {
        'change': suggestedChange,
        'new': content.suggestedNewVal(),
      };
      bool? oldVal = content.suggestedOldVal();
      if (oldVal != null) suggested['old'] = oldVal;
      result['suggested'] = suggested;
    }
    return result;
  }

  Map<String, dynamic> getSpaceParent(TimelineEventItem eventItem) {
    SpaceParentContent content = eventItem.spaceParent().expect(
      'failed to get content of m.space.parent',
    );
    Map<String, dynamic> result = {};
    String? viaChange = content.viaChange();
    if (viaChange != null) {
      final via = {'change': viaChange, 'new': content.viaNewVal().toDart()};
      FfiListFfiString? oldVal = content.viaOldVal();
      if (oldVal != null) via['old'] = oldVal.toDart();
      result['via'] = via;
    }
    String? canonicalChange = content.canonicalChange();
    if (canonicalChange != null) {
      final canonical = {
        'change': canonicalChange,
        'new': content.canonicalNewVal(),
      };
      bool? oldVal = content.canonicalOldVal();
      if (oldVal != null) canonical['old'] = oldVal;
      result['canonical'] = canonical;
    }
    return result;
  }

  // fetch event media binary for message.
  Future<void> fetchMediaBinary(
    String? msgType,
    String eventId,
    String msgId,
  ) async {
    switch (msgType) {
      case 'm.audio':
      case 'm.video':
        final messages = state.messages;

        final convo = await ref.read(chatProvider(roomId).future);
        if (convo == null) {
          throw RoomNotFound();
        }
        final data = await convo.mediaBinary(eventId, null);
        int index = messages.indexWhere((x) => x.id == msgId);
        if (index != -1) {
          final metadata = {...messages[index].metadata ?? {}};
          metadata['base64'] = base64Encode(data.asTypedList());
          final message = messages[index].copyWith(metadata: metadata);
          replaceMessageAt(index, message);
        }
        break;
    }
  }

  // Pagination Control
  Future<void> handleEndReached() async {
    await loadMore();
  }

  // preview message link
  void handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final messages = state.messages;
    final index = messages.indexWhere((x) => x.id == message.id);
    if (index != -1) {
      final updatedMessage = (messages[index] as types.TextMessage).copyWith(
        previewData: previewData,
      );
      replaceMessageAt(index, updatedMessage);
    }
  }
}
