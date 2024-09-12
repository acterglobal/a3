import 'dart:async';
import 'dart:convert';

import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/models/chat_room_state/chat_room_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:extension_nullable/extension_nullable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:logging/logging.dart';
import 'package:riverpod/riverpod.dart';

final _log = Logger('a3::chat::room_notifier');

class PostProcessItem {
  final types.Message message;
  final RoomMessage event;

  const PostProcessItem(this.event, this.message);
}

class ChatRoomNotifier extends StateNotifier<ChatRoomState> {
  final Ref ref;
  final String roomId;
  late TimelineStream timeline;
  late Stream<RoomMessageDiff> _listener;
  late StreamSubscription<RoomMessageDiff> _poller;

  ChatRoomNotifier({
    required this.roomId,
    required this.ref,
  }) : super(const ChatRoomState()) {
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
      state = state.copyWith(
        loading: ChatRoomLoadingState.error(e.toString()),
      );
    }
  }

  Future<void> loadMore({bool failOnError = false}) async {
    if (state.hasMore && !state.loading.isLoading) {
      try {
        state = state.copyWith(
          loading: const ChatRoomLoadingState.loading(),
        );
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

  // parses `RoomMessage` event to `types.Message` and updates messages list
  Future<void> handleDiff(RoomMessageDiff diff) async {
    List<PostProcessItem> postProcessing = [];
    switch (diff.action()) {
      case 'Append':
        List<RoomMessage> messages = diff.values()!.toList();
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
        RoomMessage m = diff.value()!;
        final index = diff.index()!;
        final message = parseMessage(m);
        replaceMessageAt(index, message);
        postProcessing.add(PostProcessItem(m, message));
        break;
      case 'Insert':
        RoomMessage m = diff.value()!;
        final index = diff.index()!;
        final message = parseMessage(m);
        insertMessage(index, message);
        postProcessing.add(PostProcessItem(m, message));
        break;
      case 'Remove':
        int index = diff.index()!;
        removeMessage(index);
        break;
      case 'PushBack':
        RoomMessage m = diff.value()!;
        final message = parseMessage(m);
        final newList = messagesCopy();
        newList.add(message);
        setMessages(newList);
        postProcessing.add(PostProcessItem(m, message));
        break;
      case 'PushFront':
        RoomMessage m = diff.value()!;
        final message = parseMessage(m);
        insertMessage(0, message);
        postProcessing.add(PostProcessItem(m, message));
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
        List<RoomMessage> messages = diff.values()!.toList();
        List<types.Message> newList = [];
        for (final m in messages) {
          final message = parseMessage(m);
          newList.add(message);
          postProcessing.add(PostProcessItem(m, message));
        }
        if (newList.isNotEmpty) {
          setMessages(newList);
        }
        break;
      case 'Truncate':
        final length = diff.index()!;
        final newList = messagesCopy();
        setMessages(newList.take(length).toList());
        break;
      default:
        break;
    }

    // ensure we are done with the state list to avoid
    // races between the async tasks and the diff
    if (postProcessing.isNotEmpty) {
      for (final p in postProcessing) {
        final repliedTo = getRepliedTo(p.message);
        if (repliedTo != null) {
          await fetchOriginalContent(repliedTo, p.message.id);
        }
        final eventItem = p.event.eventItem();
        final remoteId = p.message.remoteId;
        if (eventItem != null && remoteId != null) {
          await fetchMediaBinary(eventItem.msgType(), remoteId, p.message.id);
        }
      }
    }
  }

  // fetch original content media for reply msg, i.e. text/image/file etc.
  Future<void> fetchOriginalContent(String originalId, String msgId) async {
    RoomMessage roomMsg;
    try {
      roomMsg = await timeline.getMessage(originalId);
    } catch (e, s) {
      _log.severe(
        'Failing to load reference $msgId (from $originalId)',
        e,
        s,
      );
      return;
    }

    // reply is allowed for only EventItem not VirtualItem
    // user should be able to get original event as RoomMessage
    RoomEventItem orgEventItem = roomMsg.eventItem()!;
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
      case 'm.room.guest.access':
      case 'm.room.history_visibility':
      case 'm.room.join.rules':
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
      case 'm.room.redaction':
        repliedTo = types.CustomMessage(
          author: types.User(id: orgEventItem.sender()),
          createdAt: orgEventItem.originServerTs(),
          id: roomMsg.uniqueId(),
          metadata: {
            'eventType': eventType,
          },
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
            orgEventItem.msgContent().map((p0) {
              String body = p0.body();
              repliedToContent['content'] = body;
              repliedToContent['messageLength'] = body.length;
              repliedTo = types.TextMessage(
                author: types.User(id: orgEventItem.sender()),
                id: originalId,
                createdAt: orgEventItem.originServerTs(),
                text: body,
                metadata: repliedToContent,
              );
            });
            break;
          case 'm.image':
            final convo = await ref.read(chatProvider(roomId).future);
            if (convo == null) throw RoomNotFound();
            orgEventItem.msgContent().map((p0) {
              convo.mediaBinary(originalId, null).then((data) {
                repliedToContent['base64'] = base64Encode(data.asTypedList());
              });
              final src = p0.source();
              if (src == null) throw 'Image source not found';
              repliedTo = types.ImageMessage(
                author: types.User(id: orgEventItem.sender()),
                id: originalId,
                createdAt: orgEventItem.originServerTs(),
                name: p0.body(),
                size: p0.size() ?? 0,
                uri: src.url(),
                width: p0.width()?.toDouble() ?? 0,
                metadata: repliedToContent,
              );
            });
            break;
          case 'm.audio':
            final convo = await ref.read(chatProvider(roomId).future);
            if (convo == null) throw RoomNotFound();
            orgEventItem.msgContent().map((p0) {
              convo.mediaBinary(originalId, null).then((data) {
                repliedToContent['base64'] = base64Encode(data.asTypedList());
              });
              final src = p0.source();
              if (src == null) throw 'Audio source not found';
              repliedTo = types.AudioMessage(
                author: types.User(id: orgEventItem.sender()),
                id: originalId,
                createdAt: orgEventItem.originServerTs(),
                name: p0.body(),
                duration: Duration(seconds: p0.duration() ?? 0),
                size: p0.size() ?? 0,
                uri: src.url(),
                metadata: repliedToContent,
              );
            });
            break;
          case 'm.video':
            final convo = await ref.read(chatProvider(roomId).future);
            if (convo == null) throw RoomNotFound();
            orgEventItem.msgContent().map((p0) {
              convo.mediaBinary(originalId, null).then((data) {
                repliedToContent['base64'] = base64Encode(data.asTypedList());
              });
              final src = p0.source();
              if (src == null) throw 'Video source not found';
              repliedTo = types.VideoMessage(
                author: types.User(id: orgEventItem.sender()),
                id: originalId,
                createdAt: orgEventItem.originServerTs(),
                name: p0.body(),
                size: p0.size() ?? 0,
                uri: src.url(),
                metadata: repliedToContent,
              );
            });
            break;
          case 'm.file':
            orgEventItem.msgContent().map((p0) {
              final src = p0.source();
              if (src == null) throw 'File source not found';
              // preview is not needed for past file msg, so we don't load file binary
              repliedTo = types.FileMessage(
                author: types.User(id: orgEventItem.sender()),
                id: originalId,
                createdAt: orgEventItem.originServerTs(),
                name: p0.body(),
                size: p0.size() ?? 0,
                uri: src.url(),
                metadata: repliedToContent,
              );
            });
            break;
          case 'm.sticker':
            // user can’t do any action about sticker message
            break;
        }
    }

    if (repliedTo == null) return;
    final messages = state.messages;
    int index = messages.indexWhere((x) => x.id == msgId);
    if (index != -1 && repliedTo != null) {
      replaceMessageAt(
        index,
        messages[index].copyWith(repliedMessage: repliedTo),
      );
    }
  }

  // maps [RoomMessage] to [types.Message].
  types.Message parseMessage(RoomMessage message) {
    RoomVirtualItem? virtualItem = message.virtualItem();
    if (virtualItem != null) {
      final eventType = virtualItem.eventType();
      return switch (eventType) {
        'ReadMarker' => const types.SystemMessage(
            metadata: {'type': '_read_marker'},
            id: 'read-marker',
            text: 'read-until-here',
          ),
        // should not return null, before we can keep track of index in diff receiver
        _ => types.UnsupportedMessage(
            author: const types.User(id: 'virtual'),
            id: UniqueKey().toString(),
            metadata: {
              'eventType': eventType,
            },
          ),
      };
    }

    // If not virtual item, it should be event item
    RoomEventItem eventItem = message.eventItem()!;
    EventSendState? eventState = eventItem.sendState();

    String eventType = eventItem.eventType();
    String sender = eventItem.sender();
    bool isEditable = eventItem.isEditable();
    bool wasEdited = eventItem.wasEdited();
    final author = types.User(
      id: sender,
      firstName: simplifyUserId(sender),
    );
    int createdAt = eventItem.originServerTs(); // in milliseconds
    String uniqueId = message.uniqueId();
    String? eventId = eventItem.eventId();

    String? inReplyTo = eventItem.inReplyTo();

    // user read receipts for timeline event item
    Map<String, int> receipts = {};
    for (var userId in eventItem.readUsers()) {
      String id = userId.toDartString();
      eventItem.receiptTs(id).map((p0) => receipts[id] = p0);
    }

    // state event
    switch (eventType) {
      case 'm.policy.rule.room':
      case 'm.policy.rule.server':
      case 'm.policy.rule.user':
      case 'm.room.aliases':
      case 'm.room.avatar':
      case 'm.room.canonical_alias':
      case 'm.room.create':
      case 'm.room.encryption':
      case 'm.room.guest.access':
      case 'm.room.history_visibility':
      case 'm.room.join.rules':
      case 'm.room.name':
      case 'm.room.pinned_events':
      case 'm.room.power_levels':
      case 'm.room.server_acl':
      case 'm.room.third_party_invite':
      case 'm.room.tombstone':
      case 'm.room.topic':
      case 'm.space.child':
      case 'm.space.parent':
        return types.CustomMessage(
          author: author,
          createdAt: createdAt,
          id: uniqueId,
          remoteId: eventId,
          metadata: {
            'eventType': eventType,
            'body': eventItem.msgContent()?.body(),
            'eventState': eventItem.sendState(),
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
      case 'm.room.redaction':
        final metadata = {
          'eventType': eventType,
          'eventState': eventState,
          'receipts': receipts,
        };
        inReplyTo.map((p0) => metadata['repliedTo'] = p0);
        return types.CustomMessage(
          remoteId: eventId,
          author: author,
          createdAt: createdAt,
          id: uniqueId,
          metadata: metadata,
        );
      case 'm.room.member':
        MsgContent? msgContent = eventItem.msgContent();
        if (msgContent != null) {
          return types.CustomMessage(
            author: author,
            createdAt: createdAt,
            id: uniqueId,
            remoteId: eventId,
            metadata: {
              'eventType': eventType,
              'msgType': eventItem.msgType(),
              'body': msgContent.formattedBody() ?? msgContent.body(),
              'eventState': eventState,
              'receipts': receipts,
            },
          );
        }
        break;
      case 'm.room.message':
        Map<String, dynamic> metadata = {
          'eventState': eventState,
          'receipts': receipts,
          'was_edited': wasEdited,
          'isEditable': isEditable,
        };
        Map<String, dynamic> reactions = {};
        for (var key in eventItem.reactionKeys()) {
          String k = key.toDartString();
          eventItem.reactionRecords(k).map((p0) => reactions[k] = p0.toList());
        }
        switch (eventItem.msgType()) {
          case 'm.audio':
            MsgContent? msgContent = eventItem.msgContent();
            if (msgContent != null) {
              metadata['base64'] = '';
              inReplyTo.map((p0) => metadata['repliedTo'] = p0);
              if (reactions.isNotEmpty) metadata['reactions'] = reactions;
              final src = msgContent.source();
              if (src == null) throw 'Audio source not found';
              return types.AudioMessage(
                author: author,
                createdAt: createdAt,
                remoteId: eventId,
                duration: Duration(seconds: msgContent.duration() ?? 0),
                id: uniqueId,
                metadata: metadata,
                mimeType: msgContent.mimetype(),
                name: msgContent.body(),
                size: msgContent.size() ?? 0,
                uri: src.url(),
              );
            }
            break;
          case 'm.emote':
            MsgContent? msgContent = eventItem.msgContent();
            if (msgContent != null) {
              String body = msgContent.body(); // always exists
              // check whether string only contains emoji(s).
              metadata['enlargeEmoji'] = isOnlyEmojis(body);
              inReplyTo.map((p0) => metadata['repliedTo'] = p0);
              if (reactions.isNotEmpty) metadata['reactions'] = reactions;
              return types.TextMessage(
                author: author,
                remoteId: eventId,
                createdAt: createdAt,
                id: uniqueId,
                metadata: metadata,
                text: msgContent.formattedBody() ?? body,
              );
            }
            break;
          case 'm.file':
            MsgContent? msgContent = eventItem.msgContent();
            if (msgContent != null) {
              metadata['base64'] = '';
              inReplyTo.map((p0) => metadata['repliedTo'] = p0);
              if (reactions.isNotEmpty) metadata['reactions'] = reactions;
              final src = msgContent.source();
              if (src == null) throw 'File source not found';
              return types.FileMessage(
                author: author,
                remoteId: eventId,
                createdAt: createdAt,
                id: uniqueId,
                metadata: metadata,
                mimeType: msgContent.mimetype(),
                name: msgContent.body(),
                size: msgContent.size() ?? 0,
                uri: src.url(),
              );
            }
            break;
          case 'm.image':
            MsgContent? msgContent = eventItem.msgContent();
            if (msgContent != null) {
              inReplyTo.map((p0) => metadata['repliedTo'] = p0);
              if (reactions.isNotEmpty) metadata['reactions'] = reactions;
              final src = msgContent.source();
              if (src == null) throw 'Image source not found';
              return types.ImageMessage(
                author: author,
                remoteId: eventId,
                createdAt: createdAt,
                height: msgContent.height()?.toDouble(),
                id: uniqueId,
                metadata: metadata,
                name: msgContent.body(),
                size: msgContent.size() ?? 0,
                uri: src.url(),
                width: msgContent.width()?.toDouble(),
              );
            }
            break;
          case 'm.location':
            MsgContent? msgContent = eventItem.msgContent();
            if (msgContent != null) {
              metadata['eventType'] = 'm.room.message';
              metadata['msgType'] = 'm.location';
              metadata['body'] = msgContent.body();
              metadata['geoUri'] = msgContent.geoUri();
              inReplyTo.map((p0) => metadata['repliedTo'] = p0);
              if (reactions.isNotEmpty) metadata['reactions'] = reactions;
              msgContent.thumbnailSource().map((p0) {
                metadata['thumbnailSource'] = p0.url();
              });
              final thumbnailInfo = msgContent.thumbnailInfo();
              thumbnailInfo?.mimetype().map((p0) {
                metadata['thumbnailMimetype'] = p0;
              });
              thumbnailInfo?.size().map((p0) {
                metadata['thumbnailSize'] = p0;
              });
              thumbnailInfo?.width().map((p0) {
                metadata['thumbnailWidth'] = p0;
              });
              thumbnailInfo?.height().map((p0) {
                metadata['thumbnailHeight'] = p0;
              });
              return types.CustomMessage(
                author: author,
                remoteId: eventId,
                createdAt: createdAt,
                id: uniqueId,
                metadata: metadata,
              );
            }
            break;
          case 'm.notice':
          case 'm.server_notice':
          case 'm.text':
            final body = prepareMsg(eventItem.msgContent());
            // check whether string only contains emoji(s).
            metadata['enlargeEmoji'] = isOnlyEmojis(body);
            inReplyTo.map((p0) => metadata['repliedTo'] = p0);
            if (reactions.isNotEmpty) metadata['reactions'] = reactions;
            return types.TextMessage(
              author: author,
              remoteId: eventId,
              createdAt: createdAt,
              id: uniqueId,
              metadata: metadata,
              text: body,
            );
          case 'm.video':
            MsgContent? msgContent = eventItem.msgContent();
            if (msgContent != null) {
              metadata['base64'] = '';
              inReplyTo.map((p0) => metadata['repliedTo'] = p0);
              if (reactions.isNotEmpty) metadata['reactions'] = reactions;
              final src = msgContent.source();
              if (src == null) throw 'Video source not found';
              return types.VideoMessage(
                author: author,
                remoteId: eventId,
                createdAt: createdAt,
                id: uniqueId,
                metadata: metadata,
                name: msgContent.body(),
                size: msgContent.size() ?? 0,
                uri: src.url(),
              );
            }
            break;
          case 'm.key.verification.request':
            break;
        }
        break;
      case 'm.sticker':
        Map<String, dynamic> receipts = {};
        for (var userId in eventItem.readUsers()) {
          String id = userId.toDartString();
          eventItem.receiptTs(id).map((p0) => receipts[id] = p0);
        }
        Map<String, dynamic> reactions = {};
        for (var key in eventItem.reactionKeys()) {
          String k = key.toDartString();
          eventItem.reactionRecords(k).map((p0) => reactions[k] = p0.toList());
        }
        MsgContent? msgContent = eventItem.msgContent();
        if (msgContent != null) {
          Map<String, dynamic> metadata = {
            'eventType': eventType,
            'name': msgContent.body(),
            'size': msgContent.size() ?? 0,
            'width': msgContent.width()?.toDouble(),
            'height': msgContent.height()?.toDouble(),
            'base64': '',
            'eventState': eventState,
            'receipts': receipts,
            'was_edited': wasEdited,
            'isEditable': isEditable,
          };
          inReplyTo.map((p0) => metadata['repliedTo'] = p0);
          if (reactions.isNotEmpty) metadata['reactions'] = reactions;
          return types.CustomMessage(
            author: author,
            remoteId: eventId,
            createdAt: createdAt,
            id: uniqueId,
            metadata: metadata,
          );
        }
        break;
      case 'm.poll.start':
        MsgContent? msgContent = eventItem.msgContent();
        if (msgContent != null) {
          return types.CustomMessage(
            author: author,
            remoteId: eventId,
            createdAt: createdAt,
            id: uniqueId,
            metadata: {
              'eventType': eventType,
              'msgType': eventItem.msgType(),
              'body': msgContent.body(),
              'was_edited': wasEdited,
              'isEditable': isEditable,
              'eventState': eventState,
              'receipts': receipts,
            },
          );
        }
        break;
    }
    return types.UnsupportedMessage(
      author: const types.User(id: 'virtual'),
      remoteId: eventId,
      id: UniqueKey().toString(),
    );
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
