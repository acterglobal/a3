import 'dart:async';
import 'dart:convert';

import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/models/chat_room_state/chat_room_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:riverpod/riverpod.dart';

class PostProcessItem {
  final types.Message message;
  final RoomMessage event;

  const PostProcessItem(this.event, this.message);
}

class ChatRoomNotifier extends StateNotifier<ChatRoomState> {
  final Ref ref;
  final Convo convo;
  late TimelineStream timeline;
  late Stream<RoomMessageDiff> _listener;
  late StreamSubscription<RoomMessageDiff> _poller;

  ChatRoomNotifier({
    required this.convo,
    required this.ref,
  }) : super(const ChatRoomState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      timeline = ref.read(timelineStreamProvider(convo));
      _listener = timeline.messagesStream(); // keep it resident in memory
      _poller = _listener.listen(_handleDiff);
      ref.onDispose(() => _poller.cancel());
      do {
        await loadMore();
        await Future.delayed(const Duration(milliseconds: 100), () => null);
      } while (state.hasMore && state.messages.length < 10);
    } catch (e) {
      final err = 'Some error occurred loading room ${e.toString()}';
      state = state.copyWith(
        loading: ChatRoomLoadingState.error(err),
      );
    }
  }

  Future<void> loadMore() async {
    final hasMore = await timeline.paginateBackwards(20);
    // wait for diffRx to be finished
    state = state.copyWith(hasMore: hasMore);
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
    final newState = messagesCopy();
    newState[index] = m;
    state = state.copyWith(messages: newState);
  }

  void replaceMessage(types.Message m) {
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      final messages = messagesCopy();
      int index = messages.indexWhere((x) => x.id == m.id);
      if (index != -1) {
        messages[index] = m;
        state = state.copyWith(messages: messages);
      }
    });
  }

  void removeMessage(int idx) {
    final newState = messagesCopy();
    newState.removeAt(idx);
    state = state.copyWith(messages: newState);
  }

  void resetMessages() => state = state.copyWith(messages: []);

  // get the repliedTo field from metadata
  String? _getRepliedTo(types.Message message) {
    final metadata = message.metadata;
    if (metadata == null) {
      return null;
    }
    if (!metadata.containsKey('repliedTo')) {
      return null;
    }
    return metadata['repliedTo'];
  }

  // parses `RoomMessage` event to `types.Message` and updates messages list
  Future<void> _handleDiff(RoomMessageDiff diff) async {
    List<PostProcessItem> postProcessing = [];
    switch (diff.action()) {
      case 'Append':
        List<RoomMessage> messages = diff.values()!.toList();
        List<types.Message> messagesToAdd = [];
        for (final m in messages) {
          final message = _parseMessage(m);
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
        final message = _parseMessage(m);
        replaceMessageAt(index, message);
        postProcessing.add(PostProcessItem(m, message));
        break;
      case 'Insert':
        RoomMessage m = diff.value()!;
        final index = diff.index()!;
        final message = _parseMessage(m);
        insertMessage(index, message);
        postProcessing.add(PostProcessItem(m, message));
        break;
      case 'Remove':
        int index = diff.index()!;
        removeMessage(index);
        break;
      case 'PushBack':
        RoomMessage m = diff.value()!;
        final message = _parseMessage(m);
        final newList = messagesCopy();
        newList.add(message);
        setMessages(newList);
        postProcessing.add(PostProcessItem(m, message));
        break;
      case 'PushFront':
        RoomMessage m = diff.value()!;
        final message = _parseMessage(m);
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
          final message = _parseMessage(m);
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
        final message = p.message;
        final m = p.event;
        final repliedTo = _getRepliedTo(message);
        if (repliedTo != null) {
          await _fetchOriginalContent(repliedTo, message.id);
        }
        RoomEventItem? eventItem = m.eventItem();
        if (eventItem != null) {
          await _fetchMediaBinary(eventItem.msgType(), message.id);
        }
      }
    }
  }

  // fetch original content media for reply msg, i.e. text/image/file etc.
  Future<void> _fetchOriginalContent(String originalId, String replyId) async {
    final roomMsg = await timeline.getMessage(originalId);

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
        repliedTo = types.CustomMessage(
          author: types.User(id: orgEventItem.sender()),
          createdAt: orgEventItem.originServerTs(),
          id: orgEventItem.uniqueId(),
          metadata: {
            'itemType': 'event',
            'eventType': eventType,
          },
        );
        break;
      case 'm.room.redaction':
        repliedTo = types.CustomMessage(
          author: types.User(id: orgEventItem.sender()),
          createdAt: orgEventItem.originServerTs(),
          id: orgEventItem.uniqueId(),
          metadata: {
            'itemType': 'event',
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
            MsgContent? msgContent = orgEventItem.msgContent();
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
            MsgContent? msgContent = orgEventItem.msgContent();
            if (msgContent != null) {
              convo.mediaBinary(originalId, null).then((data) {
                repliedToContent['base64'] = base64Encode(data.asTypedList());
              });
              repliedTo = types.ImageMessage(
                author: types.User(id: orgEventItem.sender()),
                id: originalId,
                createdAt: orgEventItem.originServerTs(),
                name: msgContent.body(),
                size: msgContent.size() ?? 0,
                uri: msgContent.source()!.url(),
                width: msgContent.width()?.toDouble() ?? 0,
                metadata: repliedToContent,
              );
            }
            break;
          case 'm.audio':
            MsgContent? msgContent = orgEventItem.msgContent();
            if (msgContent != null) {
              convo.mediaBinary(originalId, null).then((data) {
                repliedToContent['content'] = base64Encode(data.asTypedList());
              });
              repliedTo = types.AudioMessage(
                author: types.User(id: orgEventItem.sender()),
                id: originalId,
                createdAt: orgEventItem.originServerTs(),
                name: msgContent.body(),
                duration: Duration(seconds: msgContent.duration() ?? 0),
                size: msgContent.size() ?? 0,
                uri: msgContent.source()!.url(),
                metadata: repliedToContent,
              );
            }
            break;
          case 'm.video':
            MsgContent? msgContent = orgEventItem.msgContent();
            if (msgContent != null) {
              convo.mediaBinary(originalId, null).then((data) {
                repliedToContent['content'] = base64Encode(data.asTypedList());
              });
              repliedTo = types.VideoMessage(
                author: types.User(id: orgEventItem.sender()),
                id: originalId,
                createdAt: orgEventItem.originServerTs(),
                name: msgContent.body(),
                size: msgContent.size() ?? 0,
                uri: msgContent.source()!.url(),
                metadata: repliedToContent,
              );
            }
            break;
          case 'm.file':
            MsgContent? msgContent = orgEventItem.msgContent();
            if (msgContent != null) {
              repliedToContent = {
                'content': msgContent.body(),
              };
              repliedTo = types.FileMessage(
                author: types.User(id: orgEventItem.sender()),
                id: originalId,
                createdAt: orgEventItem.originServerTs(),
                name: msgContent.body(),
                size: msgContent.size() ?? 0,
                uri: msgContent.source()!.url(),
                metadata: repliedToContent,
              );
            }
            break;
          case 'm.sticker':
            // user can't do any action about sticker message
            break;
        }
    }

    final messages = state.messages;
    int index = messages.indexWhere((x) => x.id == replyId);
    if (index != -1 && repliedTo != null) {
      replaceMessage(
        messages[index].copyWith(repliedMessage: repliedTo),
      );
    }
  }

  // maps [RoomMessage] to [types.Message].
  types.Message _parseMessage(RoomMessage message) {
    RoomVirtualItem? virtualItem = message.virtualItem();
    if (virtualItem != null) {
      // should not return null, before we can keep track of index in diff receiver
      return types.UnsupportedMessage(
        author: const types.User(id: 'virtual'),
        id: UniqueKey().toString(),
        metadata: {
          'itemType': 'virtual',
          'eventType': virtualItem.eventType(),
        },
      );
    }

    // If not virtual item, it should be event item
    RoomEventItem eventItem = message.eventItem()!;
    EventSendState? eventState;
    if (eventItem.sendState() != null) {
      eventState = eventItem.sendState();
    }

    String eventType = eventItem.eventType();
    String sender = eventItem.sender();
    bool isEditable = eventItem.isEditable();
    bool wasEdited = eventItem.wasEdited();
    final author = types.User(
      id: sender,
      firstName: simplifyUserId(sender),
    );
    int createdAt = eventItem.originServerTs(); // in milliseconds
    String eventId = eventItem.uniqueId();

    String? inReplyTo = eventItem.inReplyTo();

    // user read receipts for timeline event item
    Map<String, int> receipts = {};
    for (var userId in eventItem.readUsers()) {
      String id = userId.toDartString();
      final ts = eventItem.receiptTs(id);
      if (ts != null) {
        receipts[id] = ts;
      }
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
          id: eventId,
          metadata: {
            'itemType': 'event',
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
          author: author,
          createdAt: createdAt,
          id: eventId,
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
          author: author,
          createdAt: createdAt,
          id: eventId,
          metadata: metadata,
        );
      case 'm.room.member':
        MsgContent? msgContent = eventItem.msgContent();
        if (msgContent != null) {
          String? formattedBody = msgContent.formattedBody();
          String body = msgContent.body(); // always exists
          return types.CustomMessage(
            author: author,
            createdAt: createdAt,
            id: eventId,
            metadata: {
              'itemType': 'event',
              'eventType': eventType,
              'msgType': eventItem.msgType(),
              'body': formattedBody ?? body,
              'eventState': eventState,
              'receipts': receipts,
            },
          );
        }
        break;
      case 'm.room.message':
        Map<String, dynamic> reactions = {};
        for (var key in eventItem.reactionKeys()) {
          String k = key.toDartString();
          final records = eventItem.reactionRecords(k);
          if (records != null) {
            reactions[k] = records.toList();
          }
        }
        String? msgType = eventItem.msgType();
        switch (msgType) {
          case 'm.audio':
            MsgContent? msgContent = eventItem.msgContent();
            if (msgContent != null) {
              Map<String, dynamic> metadata = {
                'base64': '',
                'eventState': eventState,
                'receipts': receipts,
              };
              metadata['was_edited'] = wasEdited;
              metadata['isEditable'] = isEditable;
              if (inReplyTo != null) {
                metadata['repliedTo'] = inReplyTo;
              }

              if (reactions.isNotEmpty) {
                metadata['reactions'] = reactions;
              }
              return types.AudioMessage(
                author: author,
                createdAt: createdAt,
                duration: Duration(seconds: msgContent.duration() ?? 0),
                id: eventId,
                metadata: metadata,
                mimeType: msgContent.mimetype(),
                name: msgContent.body(),
                size: msgContent.size() ?? 0,
                uri: msgContent.source()!.url(),
              );
            }
            break;
          case 'm.emote':
            MsgContent? msgContent = eventItem.msgContent();
            if (msgContent != null) {
              String? formattedBody = msgContent.formattedBody();
              String body = msgContent.body(); // always exists
              Map<String, dynamic> metadata = {
                'eventState': eventState,
                'receipts': receipts,
              };
              metadata['was_edited'] = wasEdited;
              metadata['isEditable'] = isEditable;
              if (inReplyTo != null) {
                metadata['repliedTo'] = inReplyTo;
              }

              if (reactions.isNotEmpty) {
                metadata['reactions'] = reactions;
              }
              // check whether string only contains emoji(s).
              metadata['enlargeEmoji'] = isOnlyEmojis(body);
              return types.TextMessage(
                author: author,
                createdAt: createdAt,
                id: eventId,
                metadata: metadata,
                text: formattedBody ?? body,
              );
            }
            break;
          case 'm.file':
            MsgContent? msgContent = eventItem.msgContent();
            if (msgContent != null) {
              Map<String, dynamic> metadata = {
                'eventState': eventState,
                'receipts': receipts,
              };
              metadata['was_edited'] = wasEdited;
              metadata['isEditable'] = isEditable;
              if (inReplyTo != null) {
                metadata['repliedTo'] = inReplyTo;
              }

              if (reactions.isNotEmpty) {
                metadata['reactions'] = reactions;
              }
              return types.FileMessage(
                author: author,
                createdAt: createdAt,
                id: eventId,
                metadata: metadata,
                mimeType: msgContent.mimetype(),
                name: msgContent.body(),
                size: msgContent.size() ?? 0,
                uri: msgContent.source()!.url(),
              );
            }
            break;
          case 'm.image':
            MsgContent? msgContent = eventItem.msgContent();
            if (msgContent != null) {
              Map<String, dynamic> metadata = {
                'eventState': eventState,
                'receipts': receipts,
              };
              metadata['was_edited'] = wasEdited;
              metadata['isEditable'] = isEditable;
              if (inReplyTo != null) {
                metadata['repliedTo'] = inReplyTo;
              }

              if (reactions.isNotEmpty) {
                metadata['reactions'] = reactions;
              }
              return types.ImageMessage(
                author: author,
                createdAt: createdAt,
                height: msgContent.height()?.toDouble(),
                id: eventId,
                metadata: metadata,
                name: msgContent.body(),
                size: msgContent.size() ?? 0,
                uri: msgContent.source()!.url(),
                width: msgContent.width()?.toDouble(),
              );
            }
            break;
          case 'm.location':
            MsgContent? msgContent = eventItem.msgContent();
            if (msgContent != null) {
              Map<String, dynamic> metadata = {
                'itemType': 'event',
                'eventType': eventType,
                'msgType': msgType,
                'body': msgContent.body(),
                'geoUri': msgContent.geoUri(),
                'eventState': eventState,
                'receipts': receipts,
              };
              metadata['was_edited'] = wasEdited;
              metadata['isEditable'] = isEditable;
              if (inReplyTo != null) {
                metadata['repliedTo'] = inReplyTo;
              }

              if (reactions.isNotEmpty) {
                metadata['reactions'] = reactions;
              }
              final thumbnailSource = msgContent.thumbnailSource();
              if (thumbnailSource != null) {
                metadata['thumbnailSource'] = thumbnailSource.url();
              }
              final thumbnailInfo = msgContent.thumbnailInfo();
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
                createdAt: createdAt,
                id: eventId,
                metadata: metadata,
              );
            }
            break;
          case 'm.notice':
            MsgContent? msgContent = eventItem.msgContent();
            if (msgContent != null) {
              String? formattedBody = msgContent.formattedBody();
              String body = msgContent.body(); // always exists
              return types.TextMessage(
                author: author,
                createdAt: createdAt,
                id: eventId,
                text: formattedBody ?? body,
                metadata: {
                  'itemType': 'event',
                  'eventType': eventType,
                  'msgType': msgType,
                  'was_edited': wasEdited,
                  'isEditable': isEditable,
                  'eventState': eventState,
                  'receipts': receipts,
                },
              );
            }
            break;
          case 'm.server_notice':
            MsgContent? msgContent = eventItem.msgContent();
            if (msgContent != null) {
              String? formattedBody = msgContent.formattedBody();
              String body = msgContent.body(); // always exists
              return types.TextMessage(
                author: author,
                createdAt: createdAt,
                id: eventId,
                text: formattedBody ?? body,
                metadata: {
                  'itemType': 'event',
                  'eventType': eventType,
                  'msgType': msgType,
                  'was_edited': wasEdited,
                  'isEditable': isEditable,
                  'eventState': eventState,
                  'receipts': receipts,
                },
              );
            }
            break;
          case 'm.text':
            MsgContent? msgContent = eventItem.msgContent();
            if (msgContent != null) {
              String? formattedBody = msgContent.formattedBody();
              String body = msgContent.body(); // always exists
              Map<String, dynamic> metadata = {
                'eventState': eventState,
                'receipts': receipts,
              };
              metadata['was_edited'] = wasEdited;
              metadata['isEditable'] = isEditable;
              if (inReplyTo != null) {
                metadata['repliedTo'] = inReplyTo;
              }

              if (reactions.isNotEmpty) {
                metadata['reactions'] = reactions;
              }
              // check whether string only contains emoji(s).
              metadata['enlargeEmoji'] = isOnlyEmojis(body);
              return types.TextMessage(
                author: author,
                createdAt: createdAt,
                id: eventId,
                metadata: metadata,
                text: formattedBody ?? body,
              );
            }
            break;
          case 'm.video':
            MsgContent? msgContent = eventItem.msgContent();
            if (msgContent != null) {
              Map<String, dynamic> metadata = {
                'base64': '',
                'eventState': eventState,
                'receipts': receipts,
              };
              metadata['was_edited'] = wasEdited;
              metadata['isEditable'] = isEditable;
              if (inReplyTo != null) {
                metadata['repliedTo'] = inReplyTo;
              }

              if (reactions.isNotEmpty) {
                metadata['reactions'] = reactions;
              }
              return types.VideoMessage(
                author: author,
                createdAt: createdAt,
                id: eventId,
                metadata: metadata,
                name: msgContent.body(),
                size: msgContent.size() ?? 0,
                uri: msgContent.source()!.url(),
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
          final ts = eventItem.receiptTs(id);
          if (ts != null) {
            receipts[id] = ts;
          }
        }
        Map<String, dynamic> reactions = {};
        for (var key in eventItem.reactionKeys()) {
          String k = key.toDartString();
          final records = eventItem.reactionRecords(k);
          if (records != null) {
            reactions[k] = records.toList();
          }
        }
        MsgContent? msgContent = eventItem.msgContent();
        if (msgContent != null) {
          Map<String, dynamic> metadata = {
            'itemType': 'event',
            'eventType': eventType,
            'name': msgContent.body(),
            'size': msgContent.size() ?? 0,
            'width': msgContent.width()?.toDouble(),
            'height': msgContent.height()?.toDouble(),
            'base64': '',
            'eventState': eventState,
            'receipts': receipts,
          };
          metadata['was_edited'] = wasEdited;
          metadata['isEditable'] = isEditable;
          if (inReplyTo != null) {
            metadata['repliedTo'] = inReplyTo;
          }

          if (reactions.isNotEmpty) {
            metadata['reactions'] = reactions;
          }
          return types.CustomMessage(
            author: author,
            createdAt: createdAt,
            id: eventId,
            metadata: metadata,
          );
        }
        break;
      case 'm.poll.start':
        MsgContent? msgContent = eventItem.msgContent();
        if (msgContent != null) {
          String body = msgContent.body();
          return types.CustomMessage(
            author: author,
            createdAt: createdAt,
            id: eventId,
            metadata: {
              'itemType': 'event',
              'eventType': eventType,
              'msgType': eventItem.msgType(),
              'body': body,
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
      id: UniqueKey().toString(),
      metadata: const {
        'itemType': 'virtual',
      },
    );
  }

  // fetch event media binary for message.
  Future<void> _fetchMediaBinary(String? msgType, String eventId) async {
    switch (msgType) {
      case 'm.audio':
      case 'm.video':
        final messages = state.messages;
        final data = await convo.mediaBinary(eventId, null);
        int index = messages.indexWhere((x) => x.id == eventId);
        if (index != -1) {
          final metadata = {...messages[index].metadata ?? {}};
          metadata['base64'] = base64Encode(data.asTypedList());
          final message = messages[index].copyWith(metadata: metadata);
          replaceMessage(message);
        }
        break;
    }
  }

  // Pagination Control
  Future<void> handleEndReached() async {
    if (state.hasMore) {
      await loadMore();
    }
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
      replaceMessage(updatedMessage);
    }
  }
}
