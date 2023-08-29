import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/models/chat_room_state/chat_room_state.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:mime/mime.dart';

class ChatRoomNotifier extends StateNotifier<ChatRoomState> {
  final Ref ref;
  TimelineStream? timeline;
  String? currentMessageId;
  types.Message? repliedToMessage;
  List<File> fileList = [];
  late Client client;

  ChatRoomNotifier({
    required this.ref,
  }) : super(const ChatRoomState.loading()) {
    _init();
    _fetchMentionRecords();
  }

  void _init() async {
    client = ref.watch(clientProvider)!;
    try {
      final room = ref.read(currentConvoProvider)!;
      timeline = await room.timelineStream();
      StreamSubscription<TimelineDiff>? subscription;
      subscription = timeline?.diffRx().listen((event) async {
        await _parseEvent(event);
      });
      bool hasMore = false;
      do {
        hasMore = await timeline!.paginateBackwards(10);
        // wait for diffRx to be finished
        sleep(const Duration(milliseconds: 100));
      } while (hasMore && ref.read(messagesProvider).length < 10);
      ref.onDispose(() async {
        debugPrint('disposing message stream');
        await subscription?.cancel();
      });
    } catch (e) {
      state = ChatRoomState.error(
        'Some error occured loading room ${e.toString()}',
      );
    }
  }

  void isLoaded() => state = const ChatRoomState.loaded();

  bool isAuthor() {
    if (currentMessageId != null) {
      final messages = ref.read(messagesProvider);
      int index = messages.indexWhere((x) => x.id == currentMessageId);
      if (index != -1) {
        return client.userId().toString() == messages[index].author.id;
      }
    }
    return false;
  }

  // parses `RoomMessage` event to `types.Message` and updates messages list
  Future<void> _parseEvent(TimelineDiff timelineEvent) async {
    debugPrint('DiffRx: ${timelineEvent.action()}');
    final messagesNotifier = ref.read(messagesProvider.notifier);
    switch (timelineEvent.action()) {
      case 'Append':
        List<RoomMessage> messages = timelineEvent.values()!.toList();
        for (var m in messages) {
          final message = _parseMessage(m);
          if (message == null || message is types.UnsupportedMessage) {
            break;
          }
          messagesNotifier.insertMessage(0, message);
          if (message.metadata != null &&
              message.metadata!.containsKey('repliedTo')) {
            await _fetchOriginalContent(
              message.metadata?['repliedTo'],
              message.id,
            );
          }
          RoomEventItem? eventItem = m.eventItem();
          if (eventItem != null) {
            await _fetchEventContent(eventItem.subType(), message.id);
          }
        }
        break;
      case 'Set':
      case 'Insert':
        RoomMessage m = timelineEvent.value()!;
        final message = _parseMessage(m);
        if (message == null || message is types.UnsupportedMessage) {
          break;
        }
        int index = ref
            .read(messagesProvider)
            .indexWhere((msg) => message.id == msg.id);
        if (index == -1) {
          messagesNotifier.addMessage(message);
        } else {
          // update event may be fetched prior to insert event
          messagesNotifier.replaceMessage(index, message);
        }
        if (message.metadata != null &&
            message.metadata!.containsKey('repliedTo')) {
          await _fetchOriginalContent(
            message.metadata?['repliedTo'],
            message.id,
          );
        }
        RoomEventItem? eventItem = m.eventItem();
        if (eventItem != null) {
          await _fetchEventContent(eventItem.subType(), message.id);
        }
        break;
      case 'Remove':
        int index = timelineEvent.index()!;
        final messages = ref.read(messagesProvider);
        if (index < messages.length) {
          messagesNotifier.removeMessage(messages.length - 1 - index);
        }
        break;
      case 'PushBack':
        RoomMessage m = timelineEvent.value()!;
        final message = _parseMessage(m);
        if (message == null || message is types.UnsupportedMessage) {
          break;
        }
        messagesNotifier.insertMessage(0, message);
        if (message.metadata != null &&
            message.metadata!.containsKey('repliedTo')) {
          await _fetchOriginalContent(
            message.metadata?['repliedTo'],
            message.id,
          );
        }
        RoomEventItem? eventItem = m.eventItem();
        if (eventItem != null) {
          await _fetchEventContent(eventItem.subType(), message.id);
        }
        break;
      case 'PushFront':
        RoomMessage m = timelineEvent.value()!;
        final message = _parseMessage(m);
        if (message == null || message is types.UnsupportedMessage) {
          break;
        }
        messagesNotifier.addMessage(message);
        if (message.metadata != null &&
            message.metadata!.containsKey('repliedTo')) {
          await _fetchOriginalContent(
            message.metadata?['repliedTo'],
            message.id,
          );
        }
        RoomEventItem? eventItem = m.eventItem();
        if (eventItem != null) {
          await _fetchEventContent(eventItem.subType(), message.id);
        }
        break;
      case 'PopBack':
        final messages = ref.read(messagesProvider);
        if (messages.isNotEmpty) {
          messagesNotifier.removeMessage(0);
        }
        break;
      case 'PopFront':
        final messages = ref.read(messagesProvider);
        if (messages.isNotEmpty) {
          messagesNotifier.removeMessage(messages.length - 1);
        }
        break;
      case 'Clear':
        messagesNotifier.reset();
        break;
      case 'Reset':
        break;
      default:
        break;
    }
  }

  Future<void> _fetchMentionRecords() async {
    final convo = ref.read(currentConvoProvider)!;
    final activeMembers =
        await ref.read(chatMembersProvider(convo.getRoomIdStr()).future);
    List<Map<String, dynamic>> mentionRecords = [];
    final mentionListNotifier = ref.read(mentionListProvider.notifier);
    for (int i = 0; i < activeMembers.length; i++) {
      String userId = activeMembers[i].userId().toString();
      final profile = activeMembers[i].getProfile();
      Map<String, dynamic> record = {};
      final userName = (await profile.getDisplayName()).text();
      record['display'] = userName ?? simplifyUserId(userId);
      record['link'] = userId;
      mentionRecords.add(record);
      if (i % 3 == 0 || i == activeMembers.length - 1) {
        mentionListNotifier.update((state) => mentionRecords);
      }
    }
  }

  // fetch original content media for reply msg, i.e. text/image/file etc.
  Future<void> _fetchOriginalContent(String originalId, String replyId) async {
    final room = ref.read(currentConvoProvider)!;
    final roomMsg = await room.getMessage(originalId);

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
      case 'm.room.canonical.alias':
      case 'm.room.create':
      case 'm.room.encryption':
      case 'm.room.guest.access':
      case 'm.room.history.visibility':
      case 'm.room.join.rules':
      case 'm.room.name':
      case 'm.room.pinned.events':
      case 'm.room.power.levels':
      case 'm.room.server.acl':
      case 'm.room.third.party.invite':
      case 'm.room.tombstone':
      case 'm.room.topic':
      case 'm.space.child':
      case 'm.space.parent':
        break;
      case 'm.room.encrypted':
        final metadata = {
          'itemType': 'event',
          'eventType': orgEventItem.eventType()
        };
        repliedTo = types.CustomMessage(
          author: types.User(id: orgEventItem.sender()),
          createdAt: orgEventItem.originServerTs(),
          id: orgEventItem.eventId(),
          metadata: metadata,
        );
        break;
      case 'm.room.redaction':
        final metadata = {
          'itemType': 'event',
          'eventType': orgEventItem.eventType()
        };
        repliedTo = types.CustomMessage(
          author: types.User(id: orgEventItem.sender()),
          createdAt: orgEventItem.originServerTs(),
          id: orgEventItem.eventId(),
          metadata: metadata,
        );
        break;
      case 'm.call.answer':
      case 'm.call.candidates':
      case 'm.call.hangup':
      case 'm.call.invite':
        break;
      case 'm.room.message':
        String? orgMsgType = orgEventItem.subType();
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
              room.imageBinary(originalId).then((data) {
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
              room.audioBinary(originalId).then((data) {
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
              room.videoBinary(originalId).then((data) {
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

    final messages = ref.read(messagesProvider);
    int index = messages.indexWhere((x) => x.id == replyId);
    if (index != -1 && repliedTo != null) {
      messages[index] = messages[index].copyWith(repliedMessage: repliedTo);
      ref.read(messagesProvider.notifier).state = messages;
    }
  }

  // maps [RoomMessage] to [types.Message].
  types.Message? _parseMessage(RoomMessage message) {
    RoomVirtualItem? virtualItem = message.virtualItem();
    if (virtualItem != null) {
      // should not return null, before we can keep track of index in diff receiver
      return types.UnsupportedMessage(
        author: types.User(id: client.userId().toString()),
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
      reactions[k] = eventItem.reactionItems(k)?.toList();
    }
    // state event
    switch (eventType) {
      case 'm.policy.rule.room':
      case 'm.policy.rule.server':
      case 'm.policy.rule.user':
      case 'm.room.aliases':
      case 'm.room.avatar':
      case 'm.room.canonical.alias':
      case 'm.room.create':
      case 'm.room.encryption':
      case 'm.room.guest.access':
      case 'm.room.history.visibility':
      case 'm.room.join.rules':
      case 'm.room.name':
      case 'm.room.pinned.events':
      case 'm.room.power.levels':
      case 'm.room.server.acl':
      case 'm.room.third.party.invite':
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
      case 'm.key.verification.accept':
      case 'm.key.verification.cancel':
      case 'm.key.verification.done':
      case 'm.key.verification.key':
      case 'm.key.verification.mac':
      case 'm.key.verification.ready':
      case 'm.key.verification.start':
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
              'subType': eventItem.subType(),
              'body': formattedBody ?? body,
            },
          );
        }
        break;
      case 'm.room.message':
        String? subType = eventItem.subType();
        switch (subType) {
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
                  'msgType': eventItem.subType(),
                  'eventType': eventType,
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
                  'msgType': eventItem.subType(),
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
              metadata['enlargeEmoji'] = isOnlyEmojis(description.body());
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
            'eventType': 'm.sticker',
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
    return null;
  }

  // fetch event media content for message.
  Future<void> _fetchEventContent(String? subType, String eventId) async {
    switch (subType) {
      case 'm.audio':
        await _fetchAudioContent(eventId);
        break;
      case 'm.video':
        await _fetchVideoContent(eventId);
        break;
    }
  }

  // fetch audio content for message.
  Future<void> _fetchAudioContent(String eventId) async {
    final room = ref.read(currentConvoProvider)!;
    final messages = ref.read(messagesProvider);
    final messagesNotifier = ref.read(messagesProvider.notifier);
    final data = await room.audioBinary(eventId);
    int index = messages.indexWhere((x) => x.id == eventId);
    if (index != -1) {
      final metadata = messages[index].metadata ?? {};
      metadata['base64'] = base64Encode(data.asTypedList());
      messages[index] = messages[index].copyWith(metadata: metadata);
      messagesNotifier.replaceMessage(index, messages[index]);
    }
  }

  // fetch video conent for message
  Future<void> _fetchVideoContent(String eventId) async {
    final room = ref.read(currentConvoProvider)!;
    final messages = ref.read(messagesProvider);
    final messagesNotifier = ref.read(messagesProvider.notifier);
    final data = await room.videoBinary(eventId);
    int index = messages.indexWhere((x) => x.id == eventId);
    if (index != -1) {
      final metadata = messages[index].metadata ?? {};
      metadata['base64'] = base64Encode(data.asTypedList());
      messages[index] = messages[index].copyWith(metadata: metadata);
      messagesNotifier.replaceMessage(index, messages[index]);
    }
  }

  // Pagination Control
  Future<void> handleEndReached() async {
    bool hasMore = ref.read(paginationProvider);
    if (hasMore) {
      hasMore = await timeline!.paginateBackwards(10);
      ref.read(paginationProvider.notifier).update((state) => hasMore);
      debugPrint('backward pagination has more: $hasMore');
    }
  }

  // preview message link
  void handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final messages = ref.read(messagesProvider);
    final index = messages.indexWhere((x) => x.id == message.id);
    if (index != -1) {
      final updatedMessage = (messages[index] as types.TextMessage).copyWith(
        previewData: previewData,
      );
      WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
        final messagesNotifier = ref.read(messagesProvider.notifier);
        messagesNotifier.replaceMessage(index, updatedMessage);
      });
    }
  }

  // file selection
  Future<void> handleFileSelection(BuildContext context) async {
    fileList.clear();
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
    );
    if (result != null) {
      fileList = result.paths.map((path) => File(path!)).toList();
    }
  }

  Future<void> handleFileUpload() async {
    var room = ref.read(currentConvoProvider)!;
    var chatInputNotifier = ref.read(chatInputProvider.notifier);
    if (fileList.isNotEmpty) {
      try {
        for (File file in fileList) {
          String fileName = file.path.split('/').last;
          String? mimeType = lookupMimeType(file.path);

          if (mimeType!.startsWith('image/')) {
            var bytes = file.readAsBytesSync();
            var image = await decodeImageFromList(bytes);
            if (repliedToMessage != null) {
              await room.sendImageReply(
                file.path,
                fileName,
                mimeType,
                file.lengthSync(),
                image.width,
                image.height,
                repliedToMessage!.id,
                null,
              );

              repliedToMessage = null;
              chatInputNotifier.toggleReplyView(false);
              chatInputNotifier.setReplyWidget(null);
            } else {
              await room.sendImageMessage(
                file.path,
                fileName,
                mimeType,
                file.lengthSync(),
                image.height,
                image.width,
                null,
              );
            }
          } else if (mimeType.startsWith('/audio')) {
            if (repliedToMessage != null) {
            } else {}
          } else if (mimeType.startsWith('/video')) {
          } else {
            if (repliedToMessage != null) {
              await room.sendFileReply(
                file.path,
                fileName,
                mimeType,
                file.lengthSync(),
                repliedToMessage!.id,
                null,
              );
              repliedToMessage = null;
              chatInputNotifier.toggleReplyView(false);
              chatInputNotifier.setReplyWidget(null);
            } else {
              await room.sendFileMessage(
                file.path,
                fileName,
                mimeType,
                file.lengthSync(),
              );
            }
          }
        }
      } catch (e) {
        debugPrint('error occured: $e');
      }
    }
  }

  // // push messages in convo
  Future<void> handleSendPressed(
    String markdownMessage,
    int messageLength,
  ) async {
    final room = ref.read(currentConvoProvider)!;
    // image or video is sent automatically
    // user will click "send" button explicitly for text only
    await room.typingNotice(false);
    if (repliedToMessage != null) {
      await room.sendTextReply(
        markdownMessage,
        repliedToMessage!.id,
        null,
      );
      repliedToMessage = null;
      final inputNotifier = ref.read(chatInputProvider.notifier);
      inputNotifier.toggleReplyView(false);
      inputNotifier.setReplyWidget(null);
    } else {
      await room.sendFormattedMessage(markdownMessage);
    }
  }

  // message tap action
  Future<void> handleMessageTap(
    BuildContext context,
    types.Message message,
  ) async {
    final inputNotifier = ref.read(chatInputProvider.notifier);
    final roomNotifier = ref.read(chatRoomProvider.notifier);
    if (ref.read(chatInputProvider).showReplyView) {
      inputNotifier.toggleReplyView(false);
      inputNotifier.setReplyWidget(null);
    }
    roomNotifier.currentMessageId = message.id;
    inputNotifier.emojiRowVisible(true);
  }

  // send typing event from client
  Future<bool> typingNotice(bool typing) async {
    final room = ref.read(currentConvoProvider)!;
    return await room.typingNotice(typing);
  }

  // send emoji reaction to message event
  Future<void> sendEmojiReaction(String eventId, String emoji) async {
    final room = ref.read(currentConvoProvider)!;
    await room.sendReaction(eventId, emoji);
  }

// delete message event
  Future<void> redactRoomMessage(String eventId) async {
    final room = ref.read(currentConvoProvider)!;
    await room.redactMessage(eventId, '', null);
  }
}
