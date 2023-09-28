import 'dart:async';
import 'dart:convert';

import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/models/chat_room_state/chat_room_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class PostProcessItem {
  final types.Message message;
  final RoomMessage event;
  const PostProcessItem(this.event, this.message);
}

class ChatRoomNotifier extends StateNotifier<ChatRoomState> {
  final Ref ref;
  final Convo convo;
  TimelineStream? timeline;
  StreamSubscription<TimelineDiff>? subscription;

  ChatRoomNotifier({
    required this.convo,
    required this.ref,
  }) : super(const ChatRoomState()) {
    _init();
    _fetchMentionRecords();
  }

  void _init() async {
    try {
      timeline = await convo.timelineStream();
      subscription = timeline?.diffStream().listen((timelineDiff) async {
        await _handleDiff(timelineDiff);
      });
      do {
        await loadMore();
        await Future.delayed(const Duration(milliseconds: 100), () => null);
      } while (state.hasMore && state.messages.length < 10);
      ref.onDispose(() async {
        debugPrint('disposing message stream');
        await subscription?.cancel();
      });
    } catch (e) {
      state = state.copyWith(
        loading: ChatRoomLoadingState.error(
          'Some error occurred loading room ${e.toString()}',
        ),
      );
    }
  }

  Future<void> loadMore() async {
    final hasMore = await timeline!.paginateBackwards(20);
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
  Future<void> _handleDiff(TimelineDiff timelineEvent) async {
    List<PostProcessItem> postProcessing = [];
    switch (timelineEvent.action()) {
      case 'Append':
        List<RoomMessage> messages = timelineEvent.values()!.toList();
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
        RoomMessage m = timelineEvent.value()!;
        final index = timelineEvent.index()!;
        final message = _parseMessage(m);
        replaceMessageAt(index, message);
        postProcessing.add(PostProcessItem(m, message));
        break;

      case 'Insert':
        RoomMessage m = timelineEvent.value()!;
        final index = timelineEvent.index()!;
        final message = _parseMessage(m);
        insertMessage(index, message);
        postProcessing.add(PostProcessItem(m, message));
        break;
      case 'Remove':
        int index = timelineEvent.index()!;
        removeMessage(index);
        break;
      case 'PushBack':
        RoomMessage m = timelineEvent.value()!;
        final message = _parseMessage(m);
        final newList = messagesCopy();
        newList.add(message);
        setMessages(newList);
        postProcessing.add(PostProcessItem(m, message));
        break;
      case 'PushFront':
        RoomMessage m = timelineEvent.value()!;
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
        List<RoomMessage> messages = timelineEvent.values()!.toList();
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
          await _fetchEventBinary(eventItem.msgType(), message.id);
        }
      }
    }
  }

  Future<void> _fetchMentionRecords() async {
    final activeMembers =
        await ref.read(chatMembersProvider(convo.getRoomIdStr()).future);
    List<Map<String, String>> mentionRecords = [];
    final mentionListNotifier =
        ref.read(chatInputProvider(convo.getRoomIdStr()).notifier);
    for (int i = 0; i < activeMembers.length; i++) {
      String userId = activeMembers[i].userId().toString();
      final profile = activeMembers[i].getProfile();
      Map<String, String> record = {};
      final userName = (await profile.getDisplayName()).text();
      record['display'] = userName ?? simplifyUserId(userId)!;
      record['link'] = userId;
      mentionRecords.add(record);
      if (i % 3 == 0 || i == activeMembers.length - 1) {
        mentionListNotifier.setMentions(mentionRecords);
      }
    }
  }

  // fetch original content media for reply msg, i.e. text/image/file etc.
  Future<void> _fetchOriginalContent(String originalId, String replyId) async {
    final roomMsg = await convo.getMessage(originalId);

    // reply is allowed for only EventItem not VirtualItem
    // user should be able to get original event as RoomMessage
    RoomEventItem orgEventItem = roomMsg.eventItem()!;
    String eventType = orgEventItem.eventType();
    Map<String, dynamic> repliedToContent = {};
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
          id: orgEventItem.eventId(),
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
          id: orgEventItem.eventId(),
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
            TextDesc? description = orgEventItem.textDesc();
            if (description != null) {
              String body = description.body();
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
            ImageDesc? description = orgEventItem.imageDesc();
            if (description != null) {
              convo.imageBinary(originalId).then((data) {
                repliedToContent['base64'] = base64Encode(data.asTypedList());
              });
              repliedTo = types.ImageMessage(
                author: types.User(id: orgEventItem.sender()),
                id: originalId,
                createdAt: orgEventItem.originServerTs(),
                name: description.name(),
                size: description.size() ?? 0,
                uri: description.source().url(),
                width: description.width()?.toDouble() ?? 0,
                metadata: repliedToContent,
              );
            }
            break;
          case 'm.audio':
            AudioDesc? description = orgEventItem.audioDesc();
            if (description != null) {
              convo.audioBinary(originalId).then((data) {
                repliedToContent['content'] = base64Encode(data.asTypedList());
              });
              repliedTo = types.AudioMessage(
                author: types.User(id: orgEventItem.sender()),
                id: originalId,
                createdAt: orgEventItem.originServerTs(),
                name: description.name(),
                duration: Duration(seconds: description.duration() ?? 0),
                size: description.size() ?? 0,
                uri: description.source().url(),
                metadata: repliedToContent,
              );
            }
            break;
          case 'm.video':
            VideoDesc? description = orgEventItem.videoDesc();
            if (description != null) {
              convo.videoBinary(originalId).then((data) {
                repliedToContent['content'] = base64Encode(data.asTypedList());
              });
              repliedTo = types.VideoMessage(
                author: types.User(id: orgEventItem.sender()),
                id: originalId,
                createdAt: orgEventItem.originServerTs(),
                name: description.name(),
                size: description.size() ?? 0,
                uri: description.source().url(),
                metadata: repliedToContent,
              );
            }
            break;
          case 'm.file':
            FileDesc? description = orgEventItem.fileDesc();
            if (description != null) {
              repliedToContent = {
                'content': description.name(),
              };
              repliedTo = types.FileMessage(
                author: types.User(id: orgEventItem.sender()),
                id: originalId,
                createdAt: orgEventItem.originServerTs(),
                name: description.name(),
                size: description.size() ?? 0,
                uri: description.source().url(),
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

    String eventType = eventItem.eventType();
    String sender = eventItem.sender();
    final author = types.User(
      id: sender,
      firstName: simplifyUserId(sender),
    );
    int createdAt = eventItem.originServerTs(); // in milliseconds
    String eventId = eventItem.eventId();

    String? inReplyTo = eventItem.inReplyTo();
    Map<String, dynamic> reactions = {};
    for (var key in eventItem.reactionKeys()) {
      String k = key.toDartString();
      final records = eventItem.reactionRecords(k);
      if (records != null) {
        reactions[k] = records.toList();
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
            'body': eventItem.textDesc()?.body(),
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
        final metadata = {'itemType': 'event', 'eventType': eventType};
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
        final metadata = {'itemType': 'event', 'eventType': eventType};
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
        TextDesc? description = eventItem.textDesc();
        if (description != null) {
          String? formattedBody = description.formattedBody();
          String body = description.body(); // always exists
          return types.CustomMessage(
            author: author,
            createdAt: createdAt,
            id: eventId,
            metadata: {
              'itemType': 'event',
              'eventType': eventType,
              'msgType': eventItem.msgType(),
              'body': formattedBody ?? body,
            },
          );
        }
        break;
      case 'm.room.message':
        String? msgType = eventItem.msgType();
        switch (msgType) {
          case 'm.audio':
            AudioDesc? description = eventItem.audioDesc();
            if (description != null) {
              Map<String, dynamic> metadata = {'base64': ''};
              if (inReplyTo != null) {
                metadata['repliedTo'] = inReplyTo;
              }
              if (reactions.isNotEmpty) {
                metadata['reactions'] = reactions;
              }
              return types.AudioMessage(
                author: author,
                createdAt: createdAt,
                duration: Duration(seconds: description.duration() ?? 0),
                id: eventId,
                metadata: metadata,
                mimeType: description.mimetype(),
                name: description.name(),
                size: description.size() ?? 0,
                uri: description.source().url(),
              );
            }
            break;
          case 'm.emote':
            TextDesc? description = eventItem.textDesc();
            if (description != null) {
              String? formattedBody = description.formattedBody();
              String body = description.body(); // always exists
              Map<String, dynamic> metadata = {};
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
            FileDesc? description = eventItem.fileDesc();
            if (description != null) {
              Map<String, dynamic> metadata = {};
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
                mimeType: description.mimetype(),
                name: description.name(),
                size: description.size() ?? 0,
                uri: description.source().url(),
              );
            }
            break;
          case 'm.image':
            ImageDesc? description = eventItem.imageDesc();
            if (description != null) {
              Map<String, dynamic> metadata = {};
              if (inReplyTo != null) {
                metadata['repliedTo'] = inReplyTo;
              }
              if (reactions.isNotEmpty) {
                metadata['reactions'] = reactions;
              }
              return types.ImageMessage(
                author: author,
                createdAt: createdAt,
                height: description.height()?.toDouble(),
                id: eventId,
                metadata: metadata,
                name: description.name(),
                size: description.size() ?? 0,
                uri: description.source().url(),
                width: description.width()?.toDouble(),
              );
            }
            break;
          case 'm.location':
            LocationDesc? description = eventItem.locationDesc();
            if (description != null) {
              Map<String, dynamic> metadata = {
                'itemType': 'event',
                'eventType': eventType,
                'msgType': msgType,
                'body': description.body(),
                'geoUri': description.geoUri(),
              };
              if (inReplyTo != null) {
                metadata['repliedTo'] = inReplyTo;
              }
              if (reactions.isNotEmpty) {
                metadata['reactions'] = reactions;
              }
              final thumbnailSource = description.thumbnailSource();
              if (thumbnailSource != null) {
                metadata['thumbnailSource'] = thumbnailSource.toString();
              }
              final thumbnailInfo = description.thumbnailInfo();
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
            TextDesc? description = eventItem.textDesc();
            if (description != null) {
              String? formattedBody = description.formattedBody();
              String body = description.body(); // always exists
              return types.TextMessage(
                author: author,
                createdAt: createdAt,
                id: eventId,
                text: formattedBody ?? body,
                metadata: {
                  'itemType': 'event',
                  'eventType': eventType,
                  'msgType': msgType,
                },
              );
            }
            break;
          case 'm.server_notice':
            TextDesc? description = eventItem.textDesc();
            if (description != null) {
              String? formattedBody = description.formattedBody();
              String body = description.body(); // always exists
              return types.TextMessage(
                author: author,
                createdAt: createdAt,
                id: eventId,
                text: formattedBody ?? body,
                metadata: {
                  'itemType': 'event',
                  'eventType': eventType,
                  'msgType': msgType,
                },
              );
            }
            break;
          case 'm.text':
            TextDesc? description = eventItem.textDesc();
            if (description != null) {
              String? formattedBody = description.formattedBody();
              String body = description.body(); // always exists
              Map<String, dynamic> metadata = {};
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
            VideoDesc? description = eventItem.videoDesc();
            if (description != null) {
              Map<String, dynamic> metadata = {'base64': ''};
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
                name: description.name(),
                size: description.size() ?? 0,
                uri: description.source().url(),
              );
            }
            break;
          case 'm.key.verification.request':
            break;
        }
        break;
      case 'm.sticker':
        ImageDesc? description = eventItem.imageDesc();
        if (description != null) {
          Map<String, dynamic> metadata = {
            'itemType': 'event',
            'eventType': eventType,
            'name': description.name(),
            'size': description.size() ?? 0,
            'width': description.width()?.toDouble(),
            'height': description.height()?.toDouble(),
            'base64': '',
          };
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
  Future<void> _fetchEventBinary(String? msgType, String eventId) async {
    switch (msgType) {
      case 'm.audio':
        await _fetchAudioBinary(eventId);
        break;
      case 'm.video':
        await _fetchVideoBinary(eventId);
        break;
    }
  }

  // fetch audio content for message.
  Future<void> _fetchAudioBinary(String eventId) async {
    final messages = state.messages;
    final data = await convo.audioBinary(eventId);
    int index = messages.indexWhere((x) => x.id == eventId);
    if (index != -1) {
      final metadata = {...messages[index].metadata ?? {}};
      metadata['base64'] = base64Encode(data.asTypedList());
      final message = messages[index].copyWith(metadata: metadata);
      replaceMessage(message);
    }
  }

  // fetch video content for message
  Future<void> _fetchVideoBinary(String eventId) async {
    final messages = state.messages;
    final data = await convo.videoBinary(eventId);
    int index = messages.indexWhere((x) => x.id == eventId);
    if (index != -1) {
      final metadata = {...messages[index].metadata ?? {}};
      metadata['base64'] = base64Encode(data.asTypedList());
      final message = messages[index].copyWith(metadata: metadata);
      replaceMessage(message);
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
