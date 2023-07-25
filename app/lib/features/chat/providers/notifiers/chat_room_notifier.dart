import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/models/chat_room_state/chat_room_state.dart';
import 'package:acter/features/chat/pages/image_selection_page.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show
        AudioDesc,
        Client,
        Convo,
        FileDesc,
        ImageDesc,
        RoomEventItem,
        RoomMessage,
        RoomVirtualItem,
        TextDesc,
        TimelineDiff,
        TimelineStream,
        VideoDesc;
import 'package:file_picker/file_picker.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:mime/mime.dart';
import 'package:open_app_file/open_app_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatRoomNotifier extends StateNotifier<ChatRoomState> {
  final Ref ref;
  final String roomId;
  late TimelineStream timeline;
  String? emojiCurrentId;
  types.Message? repliedToMessage;
  final List<PlatformFile> _imageFileList = [];
  late Client client;
  late Convo room;
  ChatRoomNotifier({
    required this.ref,
    required this.roomId,
  }) : super(const ChatRoomState.initial()) {
    _init();
    _fetchUserProfiles();
  }

  void _init() async {
    state = const ChatRoomState.loading();
    client = ref.watch(clientProvider)!;
    if (roomId.isNotEmpty) {
      room = await ref.read(chatProvider(roomId).future);
      timeline = await room.timelineStream();
      StreamSubscription<TimelineDiff>? subscription;
      subscription = timeline.diffRx().listen((event) {
        _parseEvent(event);
        state = const ChatRoomState.loaded();
      });
      while (ref.read(messagesProvider).length <= 10) {
        await timeline.paginateBackwards(10);
      }

      ref.onDispose(() async {
        debugPrint('disposing message stream');
        await subscription?.cancel();
      });
    }
  }

  // parses `RoomMessage` event to `types.Message` and updates messages list
  Future<void> _parseEvent(TimelineDiff timelineEvent) async {
    debugPrint('DiffRx: ${timelineEvent.action()}');
    switch (timelineEvent.action()) {
      case 'Append':
        List<RoomMessage> messages = timelineEvent.values()!.toList();
        for (var m in messages) {
          var message = _parseMessage(m);
          if (message == null || message is types.UnsupportedMessage) {
            break;
          }
          ref.read(messagesProvider.notifier).insertMessage(0, message);
          if (message.metadata != null &&
              message.metadata!.containsKey('repliedTo')) {
            _fetchOriginalContent(
              message.metadata?['repliedTo'],
              message.id,
            );
          }
          RoomEventItem? eventItem = m.eventItem();
          if (eventItem != null) {
            _fetchEventContent(eventItem.subType(), message.id);
          }
        }
        break;
      case 'Set':
      case 'Insert':
        RoomMessage m = timelineEvent.value()!;
        var message = _parseMessage(m);
        debugPrint('${message?.type}');
        debugPrint('ID:${message?.id}');
        if (message == null || message is types.UnsupportedMessage) {
          break;
        }
        int index = ref
            .read(messagesProvider)
            .indexWhere((msg) => message.id == msg.id);
        if (index == -1) {
          ref.read(messagesProvider.notifier).addMessage(message);
        } else {
          // update event may be fetched prior to insert event
          ref.read(messagesProvider.notifier).replaceMessage(index, message);
        }
        if (message.metadata != null &&
            message.metadata!.containsKey('repliedTo')) {
          _fetchOriginalContent(
            message.metadata?['repliedTo'],
            message.id,
          );
        }
        RoomEventItem? eventItem = m.eventItem();
        if (eventItem != null) {
          _fetchEventContent(eventItem.subType(), message.id);
        }
        break;
      case 'Remove':
        int index = timelineEvent.index()!;
        final messages = ref.read(messagesProvider);
        if (index < messages.length) {
          ref
              .read(messagesProvider.notifier)
              .removeMessage(messages.length - 1 - index);
        }
        break;
      case 'PushBack':
        RoomMessage m = timelineEvent.value()!;
        var message = _parseMessage(m);
        if (message == null || message is types.UnsupportedMessage) {
          break;
        }
        ref.read(messagesProvider.notifier).insertMessage(0, message);
        if (message.metadata != null &&
            message.metadata!.containsKey('repliedTo')) {
          _fetchOriginalContent(
            message.metadata?['repliedTo'],
            message.id,
          );
        }
        RoomEventItem? eventItem = m.eventItem();
        if (eventItem != null) {
          _fetchEventContent(eventItem.subType(), message.id);
        }
        break;
      case 'PushFront':
        RoomMessage m = timelineEvent.value()!;
        var message = _parseMessage(m);
        if (message == null || message is types.UnsupportedMessage) {
          break;
        }
        ref.read(messagesProvider.notifier).addMessage(message);
        if (message.metadata != null &&
            message.metadata!.containsKey('repliedTo')) {
          _fetchOriginalContent(
            message.metadata?['repliedTo'],
            message.id,
          );
        }
        RoomEventItem? eventItem = m.eventItem();
        if (eventItem != null) {
          _fetchEventContent(eventItem.subType(), message.id);
        }
        break;
      case 'PopBack':
        final messages = ref.read(messagesProvider);
        if (messages.isNotEmpty) {
          ref.read(messagesProvider.notifier).removeMessage(0);
        }
        break;
      case 'PopFront':
        final messages = ref.read(messagesProvider);
        if (messages.isNotEmpty) {
          ref
              .read(messagesProvider.notifier)
              .removeMessage(messages.length - 1);
        }
        break;
      case 'Clear':
        ref.read(messagesProvider.notifier).reset();
        break;
      case 'Reset':
        break;
    }
  }

  Future<void> _fetchUserProfiles() async {
    if (roomId.isNotEmpty) {
      final activeMembers = await ref.watch(chatMembersProvider(roomId).future);
      Map<String, ProfileData> userProfiles = {};
      List<Map<String, dynamic>> mentionRecords = [];
      for (int i = 0; i < activeMembers.length; i++) {
        String userId = activeMembers[i].userId().toString();
        var profile = activeMembers[i].getProfile();
        Map<String, dynamic> record = {};
        if (await profile.hasAvatar()) {
          var userAvatar = (await profile.getThumbnail(62, 60)).data()!;
          var userName = (await profile.getDisplayName()).text();
          userProfiles[userId] = ProfileData(userName, userAvatar);
          record['avatar'] = userProfiles[userId];
        }
        var dispName = await profile.getDisplayName();
        String? name = dispName.text();
        if (name != null) {
          record['display'] = name;
        }
        record['link'] = userId;
        mentionRecords.add(record);
        if (i % 3 == 0 || i == activeMembers.length - 1) {
          ref
              .read(chatProfilesProvider.notifier)
              .update((state) => userProfiles);
          ref
              .read(mentionListProvider.notifier)
              .update((state) => mentionRecords);
        }
      }
    }
  }

// fetch original content media for reply msg .i.e. text,image,file etc.
  void _fetchOriginalContent(String originalId, String replyId) {
    room.getMessage(originalId).then((roomMsg) {
      // reply is allowed for only EventItem not VirtualItem
      // user should be able to get original event as RoomMessage
      RoomEventItem orgEventItem = roomMsg.eventItem()!;
      String? orgMsgType = orgEventItem.subType();
      Map<String, dynamic> repliedToContent = {};
      types.Message? repliedTo;
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
              repliedToContent['content'] = base64Encode(data.asTypedList());
            });
            repliedTo = types.ImageMessage(
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
      var messages = ref.read(messagesProvider);
      int index = messages.indexWhere((x) => x.id == replyId);
      if (index != -1 && repliedTo != null) {
        messages[index] = messages[index].copyWith(repliedMessage: repliedTo);
        ref
            .read(messagesProvider.notifier)
            .replaceMessage(index, messages[index]);
      }
    });
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
    debugPrint('EVENTTYPE: $eventType');
    String sender = eventItem.sender();
    debugPrint('SENDER: $sender');
    var author = types.User(id: sender, firstName: simplifyUserId(sender));
    int createdAt = eventItem.originServerTs(); // in milliseconds
    String eventId = eventItem.eventId();

    String? inReplyTo = eventItem.inReplyTo();

    Map<String, dynamic> reactions = {};
    for (var key in eventItem.reactionKeys()) {
      String k = key.toDartString();
      reactions[k] = eventItem.reactionDesc(k);
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
        return types.CustomMessage(
          author: author,
          createdAt: createdAt,
          id: eventId,
          metadata: {
            'itemType': 'event',
            'eventType': eventType,
            'repliedTo': inReplyTo,
          },
        );
      case 'm.room.redaction':
        return types.CustomMessage(
          author: author,
          createdAt: createdAt,
          id: eventId,
          metadata: {
            'itemType': 'event',
            'eventType': eventType,
            'repliedTo': inReplyTo,
          },
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
              'messageLength': body.length,
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
              Map<String, dynamic> metadata = {'base64': ''};
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
                  'messageLength': body.length,
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
                  'messageLength': body.length,
                },
              );
            }
            break;
          case 'm.text':
            TextDesc? description = eventItem.textDesc();
            if (description != null) {
              String? formattedBody = description.formattedBody();
              String body = description.body(); // always exists
              Map<String, dynamic> metadata = {
                'messageLength': body.length,
              };
              if (inReplyTo != null) {
                metadata['repliedTo'] = inReplyTo;
              }
              if (reactions.isNotEmpty) {
                metadata['reactions'] = reactions;
              }
              //check whether string only contains emoji(s).
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
  void _fetchEventContent(String? subType, String eventId) {
    switch (subType) {
      case 'm.image':
        _fetchImageContent(eventId);
        break;
      case 'm.audio':
        _fetchAudioContent(eventId);
        break;
      case 'm.video':
        _fetchVideoContent(eventId);
        break;
    }
  }

// fetch image content for message.
  void _fetchImageContent(String eventId) {
    var messages = ref.read(messagesProvider);
    room.imageBinary(eventId).then((data) {
      int index = messages.indexWhere((x) => x.id == eventId);
      if (index != -1) {
        final metadata = messages[index].metadata ?? {};
        metadata['base64'] = base64Encode(data.asTypedList());
        messages[index] = messages[index].copyWith(metadata: metadata);
        ref.read(messagesProvider.notifier).state = messages;
      }
    });
  }

// fetch audio content for message.
  void _fetchAudioContent(String eventId) {
    var messages = ref.read(messagesProvider);
    room.audioBinary(eventId).then((data) {
      int index = messages.indexWhere((x) => x.id == eventId);
      if (index != -1) {
        final metadata = messages[index].metadata ?? {};
        metadata['base64'] = base64Encode(data.asTypedList());
        messages[index] = messages[index].copyWith(metadata: metadata);
        ref.read(messagesProvider.notifier).state = messages;
      }
    });
  }

// fetch video conent for message
  void _fetchVideoContent(String eventId) {
    var messages = ref.read(messagesProvider);
    room.videoBinary(eventId).then((data) {
      int index = messages.indexWhere((x) => x.id == eventId);
      if (index != -1) {
        final metadata = messages[index].metadata ?? {};
        metadata['base64'] = base64Encode(data.asTypedList());
        messages[index] = messages[index].copyWith(metadata: metadata);
        ref.read(messagesProvider.notifier).state = messages;
      }
    });
  }

//Pagination Control
  Future<void> handleEndReached() async {
    bool hasMore = await timeline.paginateBackwards(10);
    debugPrint('backward pagination has more: $hasMore');
  }

  //preview message link
  void handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    var messages = ref.read(messagesProvider);
    final index = messages.indexWhere((x) => x.id == message.id);
    final updatedMessage = (messages[index] as types.TextMessage).copyWith(
      previewData: previewData,
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (Duration duration) => ref
          .read(messagesProvider.notifier)
          .replaceMessage(index, updatedMessage),
    );
  }

//image selection
  Future<void> handleImageSelection(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result == null) {
      return;
    }
    String? path = result.files.single.path;
    if (path == null) {
      return;
    }
    String? name = result.files.single.name;
    String? mimeType = lookupMimeType(path);
    var bytes = File(path).readAsBytesSync();
    final image = await decodeImageFromList(bytes);
    if (repliedToMessage != null) {
      await room.sendImageReply(
        path,
        name,
        mimeType!,
        bytes.length,
        image.width,
        image.height,
        repliedToMessage!.id,
        null,
      );
      final chatInputState = ref.read(chatInputProvider.notifier);
      repliedToMessage = null;
      chatInputState.toggleReplyView();
      chatInputState.setReplyWidget(null);
    } else {
      await room.sendImageMessage(
        path,
        name,
        mimeType!,
        bytes.length,
        image.width,
        image.height,
        null,
      );
    }
  }

//multiple images selection
  Future<void> handleMultipleImageSelection(BuildContext context) async {
    _imageFileList.clear();
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result == null) {
      return;
    }
    _imageFileList.addAll(result.files);
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => ImageSelectionPage(
    //       imageList: _imageFileList,
    //     ),
    //   ),
    // );
  }

//file selection
  Future<void> handleFileSelection(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );
    if (result == null) {
      return;
    }
    String? path = result.files.single.path;
    if (path == null) {
      return;
    }
    String? name = result.files.single.name;
    String? mimeType = lookupMimeType(path);
    if (repliedToMessage != null) {
      await room.sendFileReply(
        path,
        name,
        mimeType!,
        result.files.single.size,
        repliedToMessage!.id,
        null,
      );
      final chatInputState = ref.read(chatInputProvider.notifier);
      repliedToMessage = null;
      chatInputState.toggleReplyView();
      chatInputState.setReplyWidget(null);
    } else {
      await room.sendFileMessage(
        path,
        name,
        mimeType!,
        result.files.single.size,
      );
    }
  }

// push messages in convo
  Future<void> handleSendPressed(
    String markdownMessage,
    String htmlMessage,
    int messageLength,
  ) async {
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
      final chatInputState = ref.read(chatInputProvider.notifier);
      chatInputState.toggleReplyView();
      chatInputState.setReplyWidget(null);
    } else {
      await room.sendFormattedMessage(markdownMessage);
    }
  }

// message tap action
  Future<void> handleMessageTap(
    BuildContext context,
    types.Message message,
  ) async {
    if (message is types.ImageMessage ||
        message is types.AudioMessage ||
        message is types.VideoMessage ||
        message is types.FileMessage) {
      String mediaPath = await room.mediaPath(message.id);
      if (mediaPath.isEmpty) {
        Directory? rootPath = await getApplicationSupportDirectory();
        // ignore: use_build_context_synchronously
        String? dirPath = await FilesystemPicker.open(
          title: 'Save to folder',
          context: context,
          rootDirectory: rootPath,
          fsType: FilesystemType.folder,
          pickText: 'Save file to this folder',
          folderIconColor: Colors.teal,
          // ignore: use_build_context_synchronously
          requestPermission: !isDesktop(context)
              ? () async => await Permission.storage.request().isGranted
              : null,
        );
        if (dirPath != null) {
          await room.downloadMedia(message.id, dirPath);
        }
      } else {
        final result = await OpenAppFile.open(mediaPath);
        if (result.message.isNotEmpty) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
            ),
          );
        }
      }
    }
  }

// send message event with image media
  Future<void> sendImage(PlatformFile file) async {
    String? path = file.path;
    if (path == null) {
      return;
    }
    String? name = file.name;
    String? mimeType = lookupMimeType(path);
    var bytes = file.bytes;
    if (bytes == null) {
      return;
    }
    final image = await decodeImageFromList(bytes);
    if (repliedToMessage != null) {
      await room.sendImageReply(
        path,
        name,
        mimeType!,
        bytes.length,
        image.width,
        image.height,
        repliedToMessage!.id,
        null,
      );
      repliedToMessage = null;
      final chatInputState = ref.read(chatInputProvider.notifier);
      chatInputState.toggleReplyView();
      chatInputState.setReplyWidget(null);
    } else {
      await room.sendImageMessage(
        path,
        name,
        mimeType!,
        bytes.length,
        image.width,
        image.height,
        null,
      );
    }
  }

  ProfileData? getUserProfile(String userId) {
    final chatProfiles = ref.watch(chatProfilesProvider);
    if (chatProfiles.containsKey(userId)) {
      return chatProfiles[userId];
    }
    return ProfileData('', null);
  }

  void updateEmojiState(types.Message message) {
    final messages = ref.read(messagesProvider);
    int emojiMessageIndex = messages.indexWhere((x) => x.id == message.id);
    emojiCurrentId = messages[emojiMessageIndex].id;
    if (emojiCurrentId == message.id) {
      ref.read(chatInputProvider.notifier).toggleEmojiVisible();
    }
    // if (ref.read(provider)) {
    //   authorId = message.author.id;
    // }
  }

// send typing event from client
  Future<bool> typingNotice(bool typing) async =>
      await room.typingNotice(typing);

// send emoji reaction to message event
  Future<void> sendEmojiReaction(String eventId, String emoji) async =>
      await room.sendReaction(eventId, emoji);

// delete message event
  Future<void> redactRoomMessage(String eventId) async =>
      await room.redactMessage(eventId, '', null);

// shows the emoji row on message
  void toggleEmojiRow() =>
      ref.read(toggleEmojiRowProvider.notifier).update((state) => !state);
}
