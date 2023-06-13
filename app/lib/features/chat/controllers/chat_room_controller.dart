import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/models/chat_input_state/chat_input_state.dart';
import 'package:acter/features/chat/models/chat_room_state/chat_room_state.dart';
import 'package:acter/features/chat/pages/image_selection_page.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/providers/notifiers/chat_messages_notifier.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show
        AudioDesc,
        Conversation,
        DispName,
        FfiBufferUint8,
        FileDesc,
        ImageDesc,
        Member,
        RoomEventItem,
        RoomId,
        RoomMessage,
        RoomVirtualItem,
        TextDesc,
        TimelineDiff,
        TimelineStream,
        UserProfile,
        VideoDesc;
import 'package:file_picker/file_picker.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mime/mime.dart';
import 'package:open_app_file/open_app_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

final chatInputProvider =
    StateNotifierProvider<ChatInputNotifier, ChatInputState>(
  (ref) => ChatInputNotifier(ref),
);

class ChatInputNotifier extends StateNotifier<ChatInputState> {
  final Ref ref;
  FocusNode focusNode = FocusNode();
  GlobalKey<FlutterMentionsState> mentionKey =
      GlobalKey<FlutterMentionsState>();
  String? authorId;

  ChatInputNotifier(this.ref) : super(const ChatInputState()) {
    _init();
  }

  void _init() {
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        state = state.copyWith(
          isEmojiContainerVisible: false,
          isAttachmentVisible: false,
        );
      }
    });
    ref.onDispose(() {
      focusNode.removeListener(() {});
    });
  }

  void setChatInputState({
    Map<String, String>? names,
    Map<String, Future<FfiBufferUint8>>? avatars,
    Map<String, String>? messageTextMapMarkDown,
    Map<String, String>? messageTextMapHtml,
    List<Map<String, dynamic>>? mentions,
    bool? isAttachmentVisible,
    bool? isEmojiVisible,
    bool? isEmojiContainerVisible,
    bool? isSendButtonVisible,
    bool? showReplyView,
  }) {
    state = state.copyWith(
      userAvatars: avatars ?? state.userAvatars,
      usernames: names ?? state.usernames,
      mentionList: mentions ?? state.mentionList,
      isAttachmentVisible: isAttachmentVisible ?? state.isAttachmentVisible,
      isEmojiVisible: isEmojiVisible ?? state.isEmojiVisible,
      isEmojiContainerVisible:
          isEmojiContainerVisible ?? state.isEmojiContainerVisible,
      isSendButtonVisible: isSendButtonVisible ?? state.isSendButtonVisible,
      showReplyView: showReplyView ?? state.showReplyView,
      messageTextMapMarkDown:
          messageTextMapMarkDown ?? state.messageTextMapMarkDown,
      messageTextMapHtml: messageTextMapHtml ?? state.messageTextMapHtml,
    );
  }

  /// Update button state based on text editor.
  void sendButtonUpdate() => state = state.copyWith(
        isSendButtonVisible:
            mentionKey.currentState!.controller!.text.trim().isNotEmpty,
      );

  /// Disable button as soon as send button is pressed.
  void sendButtonDisable() =>
      state = state.copyWith(isSendButtonVisible: !state.isSendButtonVisible);

  void toggleEmojiContainer() => state =
      state.copyWith(isEmojiContainerVisible: !state.isEmojiContainerVisible);

  void updateEmojiState(types.Message message) {
    final _messages = ref.read(chatMessagesProvider);
    int emojiMessageIndex = _messages.indexWhere((x) => x.id == message.id);
    String? emojiCurrentId = _messages[emojiMessageIndex].id;
    if (emojiCurrentId == message.id) {
      state = state.copyWith(
        isEmojiContainerVisible: !state.isEmojiContainerVisible,
      );
    }

    if (state.isEmojiContainerVisible) {
      authorId = message.author.id;
    }
  }

  bool isAuthor() {
    final myId = ref.read(clientProvider)!.userId().toString();
    return myId == authorId;
  }

  Future<FfiBufferUint8>? getUserAvatar(String userId) =>
      state.userAvatars.containsKey(userId) ? state.userAvatars[userId] : null;

  String? getUserName(String userId) =>
      state.usernames.containsKey(userId) ? state.usernames[userId] : null;

  void reset() {
    state = state.copyWith(
      userAvatars: {},
      usernames: {},
      mentionList: [],
      isAttachmentVisible: false,
      isEmojiVisible: false,
      isEmojiContainerVisible: false,
      isSendButtonVisible: false,
    );
  }
}

final chatRoomProvider = StateNotifierProvider<ChatRoomNotifier, ChatRoomState>(
  (ref) => ChatRoomNotifier(ref),
);

class ChatRoomNotifier extends StateNotifier<ChatRoomState> {
  final Ref ref;
  TimelineStream? _stream;
  StreamSubscription<TimelineDiff>? _diffSubscription;
  StreamSubscription<RoomMessage>? _messageSubscription;
  final List<PlatformFile> _imageFileList = [];
  final bool _isDesktop = !(Platform.isAndroid || Platform.isIOS);

  ChatRoomNotifier(this.ref) : super(const ChatRoomState()) {
    _init();
  }
  // initialization call
  void _init() {
    final client = ref.read(clientProvider);
    _messageSubscription = client!.incomingMessageRx()?.listen((event) {
      // the latest message is dealt in convo receiver of ChatListController
      // here manage only its message history
      if (state.currentRoom == null) {
        return;
      }
      // filter only message of this room
      if (event.roomId() != state.currentRoom!.getRoomId()) {
        return;
      }
      // filter only message from other not me
      // it is processed in handleSendPressed
      var m = _prepareMessage(event);
      if (m is types.UnsupportedMessage) {
        return;
      }
      int index =
          ref.read(chatMessagesProvider).indexWhere((msg) => m.id == msg.id);
      if (index == -1) {
        _insertMessage(m);
      } else {
        // update event may be fetched prior to insert event
        _updateMessage(m, index);
      }
      RoomEventItem? eventItem = event.eventItem();
      if (eventItem != null) {
        if (eventItem.sender() != client.userId().toString()) {
          // if (isLoading.isFalse) {
          //   update(['Chat']);
          // }
          switch (eventItem.subType()) {
            case 'm.image':
              _fetchImageContent(m.id);
              break;
            case 'm.audio':
              _fetchAudioContent(m.id);
              break;
            case 'm.video':
              _fetchVideoContent(m.id);
              break;
          }
        }
        if (m.metadata != null && m.metadata!.containsKey('repliedTo')) {
          _fetchOriginalContent(m.metadata?['repliedTo'], m.id);
        }
      }
    });

    ref.onDispose(() {
      _messageSubscription?.cancel();
    });
  }

  void setChatRoomState({
    Conversation? currentRoom,
    List<Member>? activeMembers,
    List<types.User>? typingUsers,
    Widget? replyMessageWidget,
    types.Message? repliedToMessage,
  }) {
    state = state.copyWith(
      currentRoom: currentRoom ?? state.currentRoom,
      activeMembers: activeMembers ?? state.activeMembers,
      typingUsers: typingUsers ?? state.typingUsers,
      replyMessageWidget: replyMessageWidget ?? state.replyMessageWidget,
      repliedToMessage: repliedToMessage ?? state.repliedToMessage,
    );
  }

  // filter messages from virtual (non-render) items
  List<types.Message> getMessages() {
    final _messages = ref.read(chatMessagesProvider);
    List<types.Message> msgs = _messages.where((x) {
      if (x.metadata?['itemType'] == 'virtual') {
        // UnsupportedMessage
        return false;
      }
      return true;
    }).toList();
    return msgs;
  }

// pagination control
  Future<void> handleEndReached() async {
    bool hasMore = await _stream!.paginateBackwards(10);
    debugPrint('backward pagination has more: $hasMore');
    // _page = _page + 1;
    // update(['Chat']);
  }

  Future<void> handleMessageTap(
    BuildContext context,
    types.Message message,
  ) async {
    if (message is types.ImageMessage ||
        message is types.AudioMessage ||
        message is types.VideoMessage ||
        message is types.FileMessage) {
      String mediaPath = await state.currentRoom!.mediaPath(message.id);
      if (mediaPath.isEmpty) {
        Directory? rootPath = await getApplicationSupportDirectory();
        String? dirPath = await FilesystemPicker.open(
          title: 'Save to folder',
          context: context,
          rootDirectory: rootPath,
          fsType: FilesystemType.folder,
          pickText: 'Save file to this folder',
          folderIconColor: Colors.teal,
          requestPermission: !_isDesktop
              ? () async => await Permission.storage.request().isGranted
              : null,
        );
        if (dirPath != null) {
          await state.currentRoom!.downloadMedia(message.id, dirPath);
        }
      } else {
        final result = await OpenAppFile.open(mediaPath);
        if (result.message.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
            ),
          );
        }
      }
    }
  }

  types.Message _prepareMessage(RoomMessage message) {
    final client = ref.read(clientProvider);
    RoomVirtualItem? virtualItem = message.virtualItem();
    if (virtualItem != null) {
      // should not return null, before we can keep track of index in diff receiver
      return types.UnsupportedMessage(
        author: types.User(id: client!.userId().toString()),
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
      case 'm.reaction':
      case 'm.room.encrypted':
        return types.CustomMessage(
          author: author,
          createdAt: createdAt,
          id: eventId,
          metadata: {
            'itemType': 'event',
            'eventType': eventType,
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

    // should not return null, before we can keep track of index in diff receiver
    return types.CustomMessage(
      author: author,
      createdAt: createdAt,
      id: eventId,
      metadata: {
        'itemType': 'event',
        'eventType': eventType,
      },
    );
  }

  void _insertMessage(types.Message m) {
    final client = ref.read(clientProvider);
    if (m is! types.UnsupportedMessage) {
      List<String> seenByList =
          ref.read(receiptProvider.notifier).getSeenByList(
                state.currentRoom!.getRoomId(),
                m.createdAt!,
              );
      if (m.author.id == client!.userId().toString()) {
        types.Status status = seenByList.isEmpty
            ? types.Status.sent
            : seenByList.length < state.activeMembers.length
                ? types.Status.delivered
                : types.Status.seen;
        ref
            .read(chatMessagesProvider.notifier)
            .addMessage(m.copyWith(showStatus: true, status: status));
        return;
      }
    }
    ref.read(chatMessagesProvider.notifier).addMessage(m);
  }

  void _updateMessage(types.Message m, int index) {
    final client = ref.read(clientProvider);
    List<types.Message> _messages = ref.read(chatMessagesProvider);
    if (m is! types.UnsupportedMessage) {
      List<String> seenByList =
          ref.read(receiptProvider.notifier).getSeenByList(
                state.currentRoom!.getRoomId(),
                m.createdAt!,
              );
      if (m.author.id == client!.userId().toString()) {
        types.Status status = seenByList.isEmpty
            ? types.Status.sent
            : seenByList.length < state.activeMembers.length
                ? types.Status.delivered
                : types.Status.seen;
        _messages[index] = m.copyWith(showStatus: true, status: status);
        return;
      }
    }
    _messages[index] = m;
    ref.read(chatMessagesProvider.notifier).state = _messages;
  }

  Future<void> _fetchUserProfiles() async {
    Map<String, Future<FfiBufferUint8>> avatars = {};
    Map<String, String> names = {};
    List<String> ids = [];
    List<Map<String, dynamic>> mentionRecords = [];
    for (int i = 0; i < state.activeMembers.length; i++) {
      String userId = state.activeMembers[i].userId().toString();
      ids.add('user-profile-$userId');
      UserProfile profile = state.activeMembers[i].getProfile();
      Map<String, dynamic> record = {};
      if (await profile.hasAvatar()) {
        avatars[userId] = profile.getThumbnail(62, 60);
        record['avatar'] = avatars[userId];
      }
      DispName dispName = await profile.getDisplayName();
      String? name = dispName.text();
      if (name != null) {
        record['display'] = name;
        names[userId] = name;
      }
      record['link'] = userId;
      mentionRecords.add(record);
      if (i % 3 == 0 || i == state.activeMembers.length - 1) {
        ref.read(chatInputProvider.notifier).setChatInputState(
              names: names,
              avatars: avatars,
              mentions: mentionRecords,
            );
      }
    }
  }

  // get the timeline of room
  Future<void> setCurrentRoom(Conversation? convoRoom) async {
    if (convoRoom == null) {
      // _messages.clear();
      // typingUsers.clear();
      // // activeMembers.clear();
      // mentionList.clear();
      // _diffSubscription?.cancel();
      // _stream = null;
      // _page = 0;
      // _currentRoom = null;
      state = state.copyWith(
        currentRoom: null,
        activeMembers: [],
        typingUsers: [],
      );
      ref.read(chatMessagesProvider.notifier).state = [];
      _stream = null;
      ref.read(chatInputProvider.notifier).reset();
      _diffSubscription!.cancel();
      return;
    }
    state = state.copyWith(currentRoom: convoRoom);
    // _currentRoom = convoRoom;
    // update(['room-profile']);
    // isLoading.value = true;

    List<Member> _activeMembers = (await convoRoom.activeMembers()).toList();
    state = state.copyWith(activeMembers: _activeMembers);
    // update(['active-members']);
    _fetchUserProfiles();
    if (state.currentRoom == null) {
      // user may close chat screen before long loading completed
      ref.read(loadingProvider.notifier).update((state) => false);
      return;
    }
    _stream = await state.currentRoom!.timelineStream();
    // event handler from paginate
    _diffSubscription = _stream?.diffRx().listen((event) {
      // stream is rendered in reverse order
      switch (event.action()) {
        // Append the given elements at the end of the `Vector` and notify subscribers
        case 'Append':
          debugPrint('chat room message append');
          List<RoomMessage> values = event.values()!.toList();
          List<types.Message> _messages = ref.read(chatMessagesProvider);
          for (RoomMessage msg in values) {
            var m = _prepareMessage(msg);
            if (m is types.UnsupportedMessage) {
              continue;
            }
            _messages.insert(0, m);
            ref.read(chatMessagesProvider.notifier).state = _messages;
            if (m.metadata != null && m.metadata!.containsKey('repliedTo')) {
              _fetchOriginalContent(m.metadata?['repliedTo'], m.id);
            }
            RoomEventItem? eventItem = msg.eventItem();
            if (eventItem != null) {
              // if (isLoading.isFalse) {
              //   update(['Chat']);
              // }
              switch (eventItem.subType()) {
                case 'm.image':
                  _fetchImageContent(m.id);
                  break;
                case 'm.audio':
                  _fetchAudioContent(m.id);
                  break;
                case 'm.video':
                  _fetchVideoContent(m.id);
                  break;
              }
            }
          }
          break;
        // Insert an element at the given position and notify subscribers
        case 'Insert':
          debugPrint('chat room message insert');
          RoomMessage value = event.value()!;
          var m = _prepareMessage(value);
          if (m is types.UnsupportedMessage) {
            break;
          }
          int index = ref
              .read(chatMessagesProvider)
              .indexWhere((msg) => m.id == msg.id);
          if (index == -1) {
            _insertMessage(m);
          } else {
            // update event may be fetched prior to insert event
            _updateMessage(m, index);
          }
          if (m.metadata != null && m.metadata!.containsKey('repliedTo')) {
            _fetchOriginalContent(m.metadata?['repliedTo'], m.id);
          }
          RoomEventItem? eventItem = value.eventItem();
          if (eventItem != null) {
            // if (isLoading.isFalse) {
            //   update(['Chat']);
            // }
            switch (eventItem.subType()) {
              case 'm.image':
                _fetchImageContent(m.id);
                break;
              case 'm.audio':
                _fetchAudioContent(m.id);
                break;
              case 'm.video':
                _fetchVideoContent(m.id);
                break;
            }
          }
          break;
        // Replace the element at the given position, notify subscribers and return the previous element at that position
        case 'Set':
          debugPrint('chat room message set');
          RoomMessage value = event.value()!;
          var m = _prepareMessage(value);
          if (m is types.UnsupportedMessage) {
            break;
          }
          int index = ref
              .read(chatMessagesProvider)
              .indexWhere((msg) => m.id == msg.id);
          if (index == -1) {
            // update event may be fetched prior to insert event
            _insertMessage(m);
          } else {
            _updateMessage(m, index);
          }
          if (m.metadata != null && m.metadata!.containsKey('repliedTo')) {
            _fetchOriginalContent(m.metadata?['repliedTo'], m.id);
          }
          RoomEventItem? eventItem = value.eventItem();
          if (eventItem != null) {
            // if (isLoading.isFalse) {
            //   update(['Chat']);
            // }
            switch (eventItem.subType()) {
              case 'm.image':
                _fetchImageContent(m.id);
                break;
              case 'm.audio':
                _fetchAudioContent(m.id);
                break;
              case 'm.video':
                _fetchVideoContent(m.id);
                break;
            }
          }
          break;
        // Remove the element at the given position, notify subscribers and return the element
        case 'Remove':
          debugPrint('chat room message remove');
          List<types.Message> _messages = ref.read(chatMessagesProvider);
          int index = event.index()!;
          if (index < _messages.length) {
            _messages.removeAt(_messages.length - 1 - index);
            ref.read(chatMessagesProvider.notifier).state = _messages;
            // if (isLoading.isFalse) {
            //   update(['Chat']);
            // }
          }
          break;
        // Add an element at the back of the list and notify subscribers
        case 'PushBack':
          debugPrint('chat room message push_back');
          final _messages = ref.read(chatMessagesProvider);
          RoomMessage value = event.value()!;
          var m = _prepareMessage(value);
          if (m is types.UnsupportedMessage) {
            break;
          }
          _messages.insert(0, m);
          ref.read(chatMessagesProvider.notifier).state = _messages;
          if (m.metadata != null && m.metadata!.containsKey('repliedTo')) {
            _fetchOriginalContent(m.metadata?['repliedTo'], m.id);
          }
          RoomEventItem? eventItem = value.eventItem();
          if (eventItem != null) {
            // if (isLoading.isFalse) {
            //   update(['Chat']);
            // }
            switch (eventItem.subType()) {
              case 'm.image':
                _fetchImageContent(m.id);
                break;
              case 'm.audio':
                _fetchAudioContent(m.id);
                break;
              case 'm.video':
                _fetchVideoContent(m.id);
                break;
            }
          }
          break;
        // Add an element at the front of the list and notify subscribers
        case 'PushFront':
          debugPrint('chat room message push_front');
          RoomMessage value = event.value()!;
          var m = _prepareMessage(value);
          if (m is types.UnsupportedMessage) {
            break;
          }
          ref.read(chatMessagesProvider.notifier).addMessage(m);
          if (m.metadata != null && m.metadata!.containsKey('repliedTo')) {
            _fetchOriginalContent(m.metadata?['repliedTo'], m.id);
          }
          RoomEventItem? eventItem = value.eventItem();
          if (eventItem != null) {
            // if (isLoading.isFalse) {
            //   update(['Chat']);
            // }
            switch (eventItem.subType()) {
              case 'm.image':
                _fetchImageContent(m.id);
                break;
              case 'm.audio':
                _fetchAudioContent(m.id);
                break;
              case 'm.video':
                _fetchVideoContent(m.id);
                break;
            }
          }
          break;
        // Remove the last element, notify subscribers and return the element
        case 'PopBack':
          debugPrint('chat room message pop_back');
          List<types.Message> _messages = ref.read(chatMessagesProvider);
          if (_messages.isNotEmpty) {
            ref.read(chatMessagesProvider.notifier).removeMessage(0);
            // if (isLoading.isFalse) {
            //   update(['Chat']);
            // }
          }
          break;
        // Remove the first element, notify subscribers and return the element
        case 'PopFront':
          debugPrint('chat room message pop_front');
          List<types.Message> _messages = ref.read(chatMessagesProvider);
          if (_messages.isNotEmpty) {
            _messages.removeLast();
            ref.read(chatMessagesProvider.notifier).state = _messages;
            // if (isLoading.isFalse) {
            //   update(['Chat']);
            // }
          }
          break;
        // Clear out all of the elements in this `Vector` and notify subscribers
        case 'Clear':
          debugPrint('chat room message clear');
          ref.read(chatMessagesProvider.notifier).state = [];
          // if (isLoading.isFalse) {
          //   update(['Chat']);
          // }
          break;
        case 'Reset':
          debugPrint('chat room message reset');
          List<RoomMessage> values = event.values()!.toList();
          for (RoomMessage msg in values) {
            var m = _prepareMessage(msg);
            if (m is types.UnsupportedMessage) {
              continue;
            }
            int index = ref
                .read(chatMessagesProvider)
                .indexWhere((msg) => m.id == msg.id);
            if (index == -1) {
              _insertMessage(m);
            } else {
              // update event may be fetched prior to insert event
              _updateMessage(m, index);
            }
            if (m.metadata != null && m.metadata!.containsKey('repliedTo')) {
              _fetchOriginalContent(m.metadata?['repliedTo'], m.id);
            }
            RoomEventItem? eventItem = msg.eventItem();
            if (eventItem != null) {
              // if (isLoading.isFalse) {
              //   update(['Chat']);
              // }
              switch (eventItem.subType()) {
                case 'm.image':
                  _fetchImageContent(m.id);
                  break;
                case 'm.audio':
                  _fetchAudioContent(m.id);
                  break;
                case 'm.video':
                  _fetchVideoContent(m.id);
                  break;
              }
            }
          }
          break;
      }
    });

    if (state.currentRoom == null) {
      // user may close chat screen before long loading completed
      ref.read(loadingProvider.notifier).update((state) => false);
      return;
    }
    bool hasMore = true;

    do {
      hasMore = await _stream!.paginateBackwards(10);
      // wait for diff rx to be finished
      sleep(const Duration(milliseconds: 500));
    } while (hasMore && ref.read(chatMessagesProvider).length < 10);
    // load receipt status of room
    // var receipts = (await convoRoom.userReceipts()).toList();
    if (state.currentRoom == null) {
      // user may close chat screen before long loading completed
      ref.read(loadingProvider.notifier).update((state) => false);
      return;
    }
    // var receiptController = Get.find<ReceiptController>();
    // receiptController.loadRoom(convoRoom, receipts);
    ref.read(loadingProvider.notifier).update((state) => false);
  }

  RoomId? currentRoomId() => state.currentRoom?.getRoomId();

  void _fetchImageContent(String eventId) {
    List<types.Message> _messages = ref.read(chatMessagesProvider);
    state.currentRoom!.imageBinary(eventId).then((data) {
      int index = _messages.indexWhere((x) => x.id == eventId);
      if (index != -1) {
        final metadata = _messages[index].metadata ?? {};
        metadata['base64'] = base64Encode(data.asTypedList());
        _messages[index] = _messages[index].copyWith(metadata: metadata);
        // if (isLoading.isFalse) {
        //   update(['Chat']);
        // }
        ref.read(chatMessagesProvider.notifier).state = _messages;
      }
    });
  }

  void _fetchAudioContent(String eventId) {
    List<types.Message> _messages = ref.read(chatMessagesProvider);
    state.currentRoom!.audioBinary(eventId).then((data) {
      int index = _messages.indexWhere((x) => x.id == eventId);
      if (index != -1) {
        final metadata = _messages[index].metadata ?? {};
        metadata['base64'] = base64Encode(data.asTypedList());
        _messages[index] = _messages[index].copyWith(metadata: metadata);
        // if (isLoading.isFalse) {
        //   update(['Chat']);
        // }
        ref.read(chatMessagesProvider.notifier).state = _messages;
      }
    });
  }

  void _fetchVideoContent(String eventId) {
    List<types.Message> _messages = ref.read(chatMessagesProvider);
    state.currentRoom!.videoBinary(eventId).then((data) {
      int index = _messages.indexWhere((x) => x.id == eventId);
      if (index != -1) {
        final metadata = _messages[index].metadata ?? {};
        metadata['base64'] = base64Encode(data.asTypedList());
        _messages[index] = _messages[index].copyWith(metadata: metadata);
        // if (isLoading.isFalse) {
        //   update(['Chat']);
        // }
        ref.read(chatMessagesProvider.notifier).state = _messages;
      }
    });
  }

// fetch original content media for reply msg .i.e. text,image,file etc.
  void _fetchOriginalContent(String originalId, String replyId) {
    state.currentRoom!.getMessage(originalId).then((roomMsg) {
      // reply is allowed for only EventItem not VirtualItem
      // user should be able to get original event as RoomMessage
      RoomEventItem orgEventItem = roomMsg.eventItem()!;
      String? orgMsgType = orgEventItem.subType();
      Map<String, dynamic> repliedToContent = {};
      types.Message? repliedTo;
      if (orgMsgType == 'm.text') {
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
      } else if (orgMsgType == 'm.image') {
        ImageDesc? description = orgEventItem.imageDesc();
        if (description != null) {
          state.currentRoom!.imageBinary(originalId).then((data) {
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
      } else if (orgMsgType == 'm.audio') {
        AudioDesc? description = orgEventItem.audioDesc();
        if (description != null) {
          state.currentRoom!.audioBinary(originalId).then((data) {
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
      } else if (orgMsgType == 'm.video') {
        VideoDesc? description = orgEventItem.videoDesc();
        if (description != null) {
          state.currentRoom!.videoBinary(originalId).then((data) {
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
      } else if (orgMsgType == 'm.file') {
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
      } else if (orgMsgType == 'm.sticker') {
        // user can't do any action about sticker message
      }
      List<types.Message> _messages = ref.read(chatMessagesProvider);
      int index = _messages.indexWhere((x) => x.id == replyId);

      if (index != -1 && repliedTo != null) {
        _messages[index] = _messages[index].copyWith(repliedMessage: repliedTo);
      }
      ref.read(chatMessagesProvider.notifier).state = _messages;
      // if (isLoading.isFalse) {
      //   update(['Chat']);
      // }
    });
  }

//preview message link
  void handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    List<types.Message> _messages = ref.read(chatMessagesProvider);
    final index = _messages.indexWhere((x) => x.id == message.id);
    final updatedMessage = (_messages[index] as types.TextMessage).copyWith(
      previewData: previewData,
    );

    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      _messages[index] = updatedMessage;
      // update(['Chat']);
      ref.read(chatMessagesProvider.notifier).state = _messages;
    });
  }

  //push messages in conversation
  Future<void> handleSendPressed(
    String markdownMessage,
    String htmlMessage,
    int messageLength,
  ) async {
    // image or video is sent automatically
    // user will click "send" button explicitly for text only
    await state.currentRoom!.typingNotice(false);
    if (state.repliedToMessage != null) {
      await state.currentRoom!.sendTextReply(
        markdownMessage,
        state.repliedToMessage!.id,
        null,
      );
      state = state.copyWith(replyMessageWidget: null, repliedToMessage: null);
      ChatInputState inputState = ref.read(chatInputProvider.notifier).state;
      inputState = inputState.copyWith(showReplyView: false);
      ref.read(chatInputProvider.notifier).state = inputState;
      // update(['chat-input']);
    } else {
      await state.currentRoom!.sendFormattedMessage(markdownMessage);
    }
  }

  Future<void> handleMultipleImageSelection(
    BuildContext context,
    String roomName,
  ) async {
    _imageFileList.clear();
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result == null) {
      return;
    }
    _imageFileList.addAll(result.files);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageSelectionPage(
          imageList: _imageFileList,
          roomName: roomName,
        ),
      ),
    );
  }

  Future<void> sendImage(PlatformFile file) async {
    String? path = file.path;
    if (path == null) {
      return;
    }
    String? name = file.name;
    String? mimeType = lookupMimeType(path);
    Uint8List? bytes = file.bytes;
    if (bytes == null) {
      return;
    }
    final image = await decodeImageFromList(bytes);
    if (state.repliedToMessage != null) {
      await state.currentRoom!.sendImageReply(
        path,
        name,
        mimeType!,
        bytes.length,
        image.width,
        image.height,
        state.repliedToMessage!.id,
        null,
      );
      state = state.copyWith(replyMessageWidget: null, repliedToMessage: null);
      ChatInputState inputState = ref.read(chatInputProvider.notifier).state;
      inputState = inputState.copyWith(showReplyView: false);
      ref.read(chatInputProvider.notifier).state = inputState;
      // update(['chat-input']);
    } else {
      await state.currentRoom!.sendImageMessage(
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
    Uint8List bytes = File(path).readAsBytesSync();
    final image = await decodeImageFromList(bytes);
    if (state.repliedToMessage != null) {
      await state.currentRoom!.sendImageReply(
        path,
        name,
        mimeType!,
        bytes.length,
        image.width,
        image.height,
        state.repliedToMessage!.id,
        null,
      );
      state = state.copyWith(replyMessageWidget: null, repliedToMessage: null);
      ChatInputState inputState = ref.read(chatInputProvider.notifier).state;
      inputState = inputState.copyWith(showReplyView: false);
      ref.read(chatInputProvider.notifier).state = inputState;
      // showReplyView = false;
      // update(['chat-input']);
    } else {
      await state.currentRoom!.sendImageMessage(
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
    if (state.repliedToMessage != null) {
      await state.currentRoom!.sendFileReply(
        path,
        name,
        mimeType!,
        result.files.single.size,
        state.repliedToMessage!.id,
        null,
      );
      state = state.copyWith(replyMessageWidget: null, repliedToMessage: null);
      ChatInputState inputState = ref.read(chatInputProvider.notifier).state;
      inputState = inputState.copyWith(showReplyView: false);
      ref.read(chatInputProvider.notifier).state = inputState;
    } else {
      await state.currentRoom!.sendFileMessage(
        path,
        name,
        mimeType!,
        result.files.single.size,
      );
    }
  }

  void updateEmojiState(types.Message message) {
    final _messages = ref.read(chatMessagesProvider);
    int emojiMessageIndex = _messages.indexWhere((x) => x.id == message.id);
    String emojiCurrentId = _messages[emojiMessageIndex].id;
    if (emojiCurrentId == message.id) {
      bool oldState =
          ref.read(chatInputProvider.select((e) => e.isEmojiContainerVisible));
      ref
          .read(chatInputProvider.notifier)
          .setChatInputState(isEmojiContainerVisible: !oldState);
    }
  }

  Future<bool> typingNotice(bool typing) async {
    if (state.currentRoom == null) {
      return Future.value(false);
    }
    return await state.currentRoom!.typingNotice(typing);
  }

  Future<void> sendEmojiReaction(String eventId, String emoji) async {
    await state.currentRoom!.sendReaction(eventId, emoji);
  }

  Future<void> redactRoomMessage(String eventId) async {
    await state.currentRoom!.redactMessage(eventId, '', null);
  }
}

// class ChatRoomController extends GetxController {
//   Client client;
//   late String myId;
//   final List<types.Message> _messages = [];
//   List<types.User> typingUsers = [];
//   TimelineStream? _stream;
//   RxBool isLoading = false.obs;
//   int _page = 0;
//   Conversation? _currentRoom;

//   RxBool isEmojiVisible = false.obs;
//   RxBool isAttachmentVisible = false.obs;
//   FocusNode focusNode = FocusNode();
//   GlobalKey<FlutterMentionsState> mentionKey =
//       GlobalKey<FlutterMentionsState>();
//   bool isSendButtonVisible = false;
//   bool isEmojiContainerVisible = false;
//   final List<PlatformFile> _imageFileList = [];
//   // List<Member> activeMembers = [];
//   Map<String, String> messageTextMapMarkDown = {};
//   Map<String, String> messageTextMapHtml = {};
//   final Map<String, Future<FfiBufferUint8>> _userAvatars = {};
//   final Map<String, String> _userNames = {};
//   List<Map<String, dynamic>> mentionList = [];
//   StreamSubscription<TimelineDiff>? _diffSubscription;
//   StreamSubscription<RoomMessage>? _messageSubscription;
//   int emojiMessageIndex = 0;
//   String? emojiCurrentId;
//   String? authorId;
//   bool showReplyView = false;
//   Widget? replyMessageWidget;
//   types.Message? repliedToMessage;

//   ChatRoomController({required this.client}) : super();

//   @override
//   void onInit() {
//     super.onInit();
//     myId = client.userId().toString();
//     focusNode.addListener(() {
//       if (focusNode.hasFocus) {
//         isEmojiVisible.value = false;
//         isAttachmentVisible.value = false;
//       }
//     });

//     _messageSubscription = client.incomingMessageRx()?.listen((event) {
//       // the latest message is dealt in convo receiver of ChatListController
//       // here manage only its message history
//       if (_currentRoom == null) {
//         return;
//       }
//       // filter only message of this room
//       if (event.roomId() != _currentRoom!.getRoomId()) {
//         return;
//       }
//       // filter only message from other not me
//       // it is processed in handleSendPressed
//       var m = _prepareMessage(event);
//       if (m is types.UnsupportedMessage) {
//         return;
//       }
//       int index = _messages.indexWhere((msg) => m.id == msg.id);
//       if (index == -1) {
//         _insertMessage(m);
//       } else {
//         // update event may be fetched prior to insert event
//         _updateMessage(m, index);
//       }
//       RoomEventItem? eventItem = event.eventItem();
//       if (eventItem != null) {
//         if (eventItem.sender() != myId) {
//           if (isLoading.isFalse) {
//             update(['Chat']);
//           }
//           switch (eventItem.subType()) {
//             case 'm.image':
//               _fetchImageContent(m.id);
//               break;
//             case 'm.audio':
//               _fetchAudioContent(m.id);
//               break;
//             case 'm.video':
//               _fetchVideoContent(m.id);
//               break;
//           }
//         }
//         if (m.metadata != null && m.metadata!.containsKey('repliedTo')) {
//           _fetchOriginalContent(m.metadata?['repliedTo'], m.id);
//         }
//       }
//     });
//   }

//   @override
//   void onClose() {
//     focusNode.removeListener(() {});
//     _diffSubscription?.cancel();
//     _messageSubscription?.cancel();

//     super.onClose();
//   }

//   // get the timeline of room
//   Future<void> setCurrentRoom(Conversation? convoRoom) async {
//     if (convoRoom == null) {
//       _messages.clear();
//       typingUsers.clear();
//       // activeMembers.clear();
//       mentionList.clear();
//       _diffSubscription?.cancel();
//       _stream = null;
//       _page = 0;
//       _currentRoom = null;
//       return;
//     }
//     _currentRoom = convoRoom;
//     update(['room-profile']);
//     isLoading.value = true;
//     // activeMembers = (await convoRoom.activeMembers()).toList();
//     update(['active-members']);
//     _fetchUserProfiles();
//     if (_currentRoom == null) {
//       // user may close chat screen before long loading completed
//       isLoading.value = false;
//       return;
//     }
//     _stream = await _currentRoom!.timelineStream();
//     // event handler from paginate
//     _diffSubscription = _stream?.diffRx().listen((event) {
//       // stream is rendered in reverse order
//       switch (event.action()) {
//         // Append the given elements at the end of the `Vector` and notify subscribers
//         case 'Append':
//           debugPrint('chat room message append');
//           List<RoomMessage> values = event.values()!.toList();
//           for (RoomMessage msg in values) {
//             var m = _prepareMessage(msg);
//             if (m is types.UnsupportedMessage) {
//               continue;
//             }
//             _messages.insert(0, m);
//             if (m.metadata != null && m.metadata!.containsKey('repliedTo')) {
//               _fetchOriginalContent(m.metadata?['repliedTo'], m.id);
//             }
//             RoomEventItem? eventItem = msg.eventItem();
//             if (eventItem != null) {
//               if (isLoading.isFalse) {
//                 update(['Chat']);
//               }
//               switch (eventItem.subType()) {
//                 case 'm.image':
//                   _fetchImageContent(m.id);
//                   break;
//                 case 'm.audio':
//                   _fetchAudioContent(m.id);
//                   break;
//                 case 'm.video':
//                   _fetchVideoContent(m.id);
//                   break;
//               }
//             }
//           }
//           break;
//         // Insert an element at the given position and notify subscribers
//         case 'Insert':
//           debugPrint('chat room message insert');
//           RoomMessage value = event.value()!;
//           var m = _prepareMessage(value);
//           if (m is types.UnsupportedMessage) {
//             break;
//           }
//           int index = _messages.indexWhere((msg) => m.id == msg.id);
//           if (index == -1) {
//             _insertMessage(m);
//           } else {
//             // update event may be fetched prior to insert event
//             _updateMessage(m, index);
//           }
//           if (m.metadata != null && m.metadata!.containsKey('repliedTo')) {
//             _fetchOriginalContent(m.metadata?['repliedTo'], m.id);
//           }
//           RoomEventItem? eventItem = value.eventItem();
//           if (eventItem != null) {
//             if (isLoading.isFalse) {
//               update(['Chat']);
//             }
//             switch (eventItem.subType()) {
//               case 'm.image':
//                 _fetchImageContent(m.id);
//                 break;
//               case 'm.audio':
//                 _fetchAudioContent(m.id);
//                 break;
//               case 'm.video':
//                 _fetchVideoContent(m.id);
//                 break;
//             }
//           }
//           break;
//         // Replace the element at the given position, notify subscribers and return the previous element at that position
//         case 'Set':
//           debugPrint('chat room message set');
//           RoomMessage value = event.value()!;
//           var m = _prepareMessage(value);
//           if (m is types.UnsupportedMessage) {
//             break;
//           }
//           int index = _messages.indexWhere((msg) => m.id == msg.id);
//           if (index == -1) {
//             // update event may be fetched prior to insert event
//             _insertMessage(m);
//           } else {
//             _updateMessage(m, index);
//           }
//           if (m.metadata != null && m.metadata!.containsKey('repliedTo')) {
//             _fetchOriginalContent(m.metadata?['repliedTo'], m.id);
//           }
//           RoomEventItem? eventItem = value.eventItem();
//           if (eventItem != null) {
//             if (isLoading.isFalse) {
//               update(['Chat']);
//             }
//             switch (eventItem.subType()) {
//               case 'm.image':
//                 _fetchImageContent(m.id);
//                 break;
//               case 'm.audio':
//                 _fetchAudioContent(m.id);
//                 break;
//               case 'm.video':
//                 _fetchVideoContent(m.id);
//                 break;
//             }
//           }
//           break;
//         // Remove the element at the given position, notify subscribers and return the element
//         case 'Remove':
//           debugPrint('chat room message remove');
//           int index = event.index()!;
//           if (index < _messages.length) {
//             _messages.removeAt(_messages.length - 1 - index);
//             if (isLoading.isFalse) {
//               update(['Chat']);
//             }
//           }
//           break;
//         // Add an element at the back of the list and notify subscribers
//         case 'PushBack':
//           debugPrint('chat room message push_back');
//           RoomMessage value = event.value()!;
//           var m = _prepareMessage(value);
//           if (m is types.UnsupportedMessage) {
//             break;
//           }
//           _messages.insert(0, m);
//           if (m.metadata != null && m.metadata!.containsKey('repliedTo')) {
//             _fetchOriginalContent(m.metadata?['repliedTo'], m.id);
//           }
//           RoomEventItem? eventItem = value.eventItem();
//           if (eventItem != null) {
//             if (isLoading.isFalse) {
//               update(['Chat']);
//             }
//             switch (eventItem.subType()) {
//               case 'm.image':
//                 _fetchImageContent(m.id);
//                 break;
//               case 'm.audio':
//                 _fetchAudioContent(m.id);
//                 break;
//               case 'm.video':
//                 _fetchVideoContent(m.id);
//                 break;
//             }
//           }
//           break;
//         // Add an element at the front of the list and notify subscribers
//         case 'PushFront':
//           debugPrint('chat room message push_front');
//           RoomMessage value = event.value()!;
//           var m = _prepareMessage(value);
//           if (m is types.UnsupportedMessage) {
//             break;
//           }
//           _messages.add(m);
//           if (m.metadata != null && m.metadata!.containsKey('repliedTo')) {
//             _fetchOriginalContent(m.metadata?['repliedTo'], m.id);
//           }
//           RoomEventItem? eventItem = value.eventItem();
//           if (eventItem != null) {
//             if (isLoading.isFalse) {
//               update(['Chat']);
//             }
//             switch (eventItem.subType()) {
//               case 'm.image':
//                 _fetchImageContent(m.id);
//                 break;
//               case 'm.audio':
//                 _fetchAudioContent(m.id);
//                 break;
//               case 'm.video':
//                 _fetchVideoContent(m.id);
//                 break;
//             }
//           }
//           break;
//         // Remove the last element, notify subscribers and return the element
//         case 'PopBack':
//           debugPrint('chat room message pop_back');
//           if (_messages.isNotEmpty) {
//             _messages.removeAt(0);
//             if (isLoading.isFalse) {
//               update(['Chat']);
//             }
//           }
//           break;
//         // Remove the first element, notify subscribers and return the element
//         case 'PopFront':
//           debugPrint('chat room message pop_front');
//           if (_messages.isNotEmpty) {
//             _messages.removeLast();
//             if (isLoading.isFalse) {
//               update(['Chat']);
//             }
//           }
//           break;
//         // Clear out all of the elements in this `Vector` and notify subscribers
//         case 'Clear':
//           debugPrint('chat room message clear');
//           _messages.clear();
//           if (isLoading.isFalse) {
//             update(['Chat']);
//           }
//           break;
//         case 'Reset':
//           debugPrint('chat room message reset');
//           List<RoomMessage> values = event.values()!.toList();
//           for (RoomMessage msg in values) {
//             var m = _prepareMessage(msg);
//             if (m is types.UnsupportedMessage) {
//               continue;
//             }
//             int index = _messages.indexWhere((msg) => m.id == msg.id);
//             if (index == -1) {
//               _insertMessage(m);
//             } else {
//               // update event may be fetched prior to insert event
//               _updateMessage(m, index);
//             }
//             if (m.metadata != null && m.metadata!.containsKey('repliedTo')) {
//               _fetchOriginalContent(m.metadata?['repliedTo'], m.id);
//             }
//             RoomEventItem? eventItem = msg.eventItem();
//             if (eventItem != null) {
//               if (isLoading.isFalse) {
//                 update(['Chat']);
//               }
//               switch (eventItem.subType()) {
//                 case 'm.image':
//                   _fetchImageContent(m.id);
//                   break;
//                 case 'm.audio':
//                   _fetchAudioContent(m.id);
//                   break;
//                 case 'm.video':
//                   _fetchVideoContent(m.id);
//                   break;
//               }
//             }
//           }
//           break;
//       }
//     });

//     if (_currentRoom == null) {
//       // user may close chat screen before long loading completed
//       isLoading.value = false;
//       return;
//     }
//     bool hasMore = true;
//     do {
//       hasMore = await _stream!.paginateBackwards(10);
//       // wait for diff rx to be finished
//       sleep(const Duration(milliseconds: 500));
//     } while (hasMore && _messages.length < 10);
//     // load receipt status of room
//     // var receipts = (await convoRoom.userReceipts()).toList();
//     if (_currentRoom == null) {
//       // user may close chat screen before long loading completed
//       isLoading.value = false;
//       return;
//     }
//     // var receiptController = Get.find<ReceiptController>();
//     // receiptController.loadRoom(convoRoom, receipts);
//     isLoading.value = false;
//   }

//   //preview message link
//   void handlePreviewDataFetched(
//     types.TextMessage message,
//     types.PreviewData previewData,
//   ) {
//     final index = _messages.indexWhere((x) => x.id == message.id);
//     final updatedMessage = (_messages[index] as types.TextMessage).copyWith(
//       previewData: previewData,
//     );

//     WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
//       _messages[index] = updatedMessage;
//       update(['Chat']);
//     });
//   }

//   //push messages in conversation
//   Future<void> handleSendPressed(
//     String markdownMessage,
//     String htmlMessage,
//     int messageLength,
//   ) async {
//     // image or video is sent automatically
//     // user will click "send" button explicitly for text only
//     await _currentRoom!.typingNotice(false);
//     if (repliedToMessage != null) {
//       await _currentRoom!.sendTextReply(
//         markdownMessage,
//         repliedToMessage!.id,
//         null,
//       );
//       repliedToMessage = null;
//       replyMessageWidget = null;
//       showReplyView = false;
//       update(['chat-input']);
//     } else {
//       await _currentRoom!.sendFormattedMessage(markdownMessage);
//     }
//   }

//   Future<void> handleMultipleImageSelection(
//     BuildContext context,
//     String roomName,
//   ) async {
//     _imageFileList.clear();
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.image,
//       allowMultiple: true,
//     );
//     if (result == null) {
//       return;
//     }
//     _imageFileList.addAll(result.files);
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => ImageSelectionPage(
//           imageList: _imageFileList,
//           roomName: roomName,
//         ),
//       ),
//     );
//   }

//   Future<void> sendImage(PlatformFile file) async {
//     String? path = file.path;
//     if (path == null) {
//       return;
//     }
//     String? name = file.name;
//     String? mimeType = lookupMimeType(path);
//     Uint8List? bytes = file.bytes;
//     if (bytes == null) {
//       return;
//     }
//     final image = await decodeImageFromList(bytes);
//     if (repliedToMessage != null) {
//       await _currentRoom!.sendImageReply(
//         path,
//         name,
//         mimeType!,
//         bytes.length,
//         image.width,
//         image.height,
//         repliedToMessage!.id,
//         null,
//       );
//       repliedToMessage = null;
//       replyMessageWidget = null;
//       showReplyView = false;
//       update(['chat-input']);
//     } else {
//       await _currentRoom!.sendImageMessage(
//         path,
//         name,
//         mimeType!,
//         bytes.length,
//         image.width,
//         image.height,
//         null,
//       );
//     }
//   }

//   //image selection
//   Future<void> handleImageSelection(BuildContext context) async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.image,
//     );
//     if (result == null) {
//       return;
//     }
//     String? path = result.files.single.path;
//     if (path == null) {
//       return;
//     }
//     String? name = result.files.single.name;
//     String? mimeType = lookupMimeType(path);
//     Uint8List bytes = File(path).readAsBytesSync();
//     final image = await decodeImageFromList(bytes);
//     if (repliedToMessage != null) {
//       await _currentRoom!.sendImageReply(
//         path,
//         name,
//         mimeType!,
//         bytes.length,
//         image.width,
//         image.height,
//         repliedToMessage!.id,
//         null,
//       );
//       repliedToMessage = null;
//       replyMessageWidget = null;
//       showReplyView = false;
//       update(['chat-input']);
//     } else {
//       await _currentRoom!.sendImageMessage(
//         path,
//         name,
//         mimeType!,
//         bytes.length,
//         image.width,
//         image.height,
//         null,
//       );
//     }
//   }

//   //file selection
//   Future<void> handleFileSelection(BuildContext context) async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.any,
//     );
//     if (result == null) {
//       return;
//     }
//     String? path = result.files.single.path;
//     if (path == null) {
//       return;
//     }
//     String? name = result.files.single.name;
//     String? mimeType = lookupMimeType(path);
//     if (repliedToMessage != null) {
//       await _currentRoom!.sendFileReply(
//         path,
//         name,
//         mimeType!,
//         result.files.single.size,
//         repliedToMessage!.id,
//         null,
//       );
//       repliedToMessage = null;
//       replyMessageWidget = null;
//       showReplyView = false;
//       update(['chat-input']);
//     } else {
//       await _currentRoom!.sendFileMessage(
//         path,
//         name,
//         mimeType!,
//         result.files.single.size,
//       );
//     }
//   }



//   //Pagination Control
//   Future<void> handleEndReached() async {
//     bool hasMore = await _stream!.paginateBackwards(10);
//     debugPrint('backward pagination has more: $hasMore');
//     _page = _page + 1;
//     update(['Chat']);
//   }

//   types.Message _prepareMessage(RoomMessage message) {
//     RoomVirtualItem? virtualItem = message.virtualItem();
//     if (virtualItem != null) {
//       // should not return null, before we can keep track of index in diff receiver
//       return types.UnsupportedMessage(
//         author: types.User(id: myId),
//         id: UniqueKey().toString(),
//         metadata: {
//           'itemType': 'virtual',
//           'eventType': virtualItem.eventType(),
//         },
//       );
//     }

//     // If not virtual item, it should be event item
//     RoomEventItem eventItem = message.eventItem()!;

//     String eventType = eventItem.eventType();
//     String sender = eventItem.sender();
//     var author = types.User(id: sender, firstName: simplifyUserId(sender));
//     int createdAt = eventItem.originServerTs(); // in milliseconds
//     String eventId = eventItem.eventId();

//     String? inReplyTo = eventItem.inReplyTo();

//     Map<String, dynamic> reactions = {};
//     for (var key in eventItem.reactionKeys()) {
//       String k = key.toDartString();
//       reactions[k] = eventItem.reactionDesc(k);
//     }
//     // state event
//     switch (eventType) {
//       case 'm.policy.rule.room':
//       case 'm.policy.rule.server':
//       case 'm.policy.rule.user':
//       case 'm.room.aliases':
//       case 'm.room.avatar':
//       case 'm.room.canonical.alias':
//       case 'm.room.create':
//       case 'm.room.encryption':
//       case 'm.room.guest.access':
//       case 'm.room.history.visibility':
//       case 'm.room.join.rules':
//       case 'm.room.name':
//       case 'm.room.pinned.events':
//       case 'm.room.power.levels':
//       case 'm.room.server.acl':
//       case 'm.room.third.party.invite':
//       case 'm.room.tombstone':
//       case 'm.room.topic':
//       case 'm.space.child':
//       case 'm.space.parent':
//         return types.CustomMessage(
//           author: author,
//           createdAt: createdAt,
//           id: eventId,
//           metadata: {
//             'itemType': 'event',
//             'eventType': eventType,
//             'body': eventItem.textDesc()?.body(),
//           },
//         );
//     }

//     // message event
//     switch (eventType) {
//       case 'm.call.answer':
//       case 'm.call.candidates':
//       case 'm.call.hangup':
//       case 'm.call.invite':
//       case 'm.key.verification.accept':
//       case 'm.key.verification.cancel':
//       case 'm.key.verification.done':
//       case 'm.key.verification.key':
//       case 'm.key.verification.mac':
//       case 'm.key.verification.ready':
//       case 'm.key.verification.start':
//       case 'm.reaction':
//       case 'm.room.encrypted':
//         return types.CustomMessage(
//           author: author,
//           createdAt: createdAt,
//           id: eventId,
//           metadata: {
//             'itemType': 'event',
//             'eventType': eventType,
//           },
//         );
//       case 'm.room.redaction':
//         return types.CustomMessage(
//           author: author,
//           createdAt: createdAt,
//           id: eventId,
//           metadata: {
//             'itemType': 'event',
//             'eventType': eventType,
//           },
//         );
//       case 'm.room.member':
//         TextDesc? description = eventItem.textDesc();
//         if (description != null) {
//           String? formattedBody = description.formattedBody();
//           String body = description.body(); // always exists
//           return types.CustomMessage(
//             author: author,
//             createdAt: createdAt,
//             id: eventId,
//             metadata: {
//               'itemType': 'event',
//               'eventType': eventType,
//               'subType': eventItem.subType(),
//               'messageLength': body.length,
//               'body': formattedBody ?? body,
//             },
//           );
//         }
//         break;
//       case 'm.room.message':
//         String? subType = eventItem.subType();
//         switch (subType) {
//           case 'm.audio':
//             AudioDesc? description = eventItem.audioDesc();
//             if (description != null) {
//               Map<String, dynamic> metadata = {'base64': ''};
//               if (inReplyTo != null) {
//                 metadata['repliedTo'] = inReplyTo;
//               }
//               if (reactions.isNotEmpty) {
//                 metadata['reactions'] = reactions;
//               }
//               return types.AudioMessage(
//                 author: author,
//                 createdAt: createdAt,
//                 duration: Duration(seconds: description.duration() ?? 0),
//                 id: eventId,
//                 metadata: metadata,
//                 mimeType: description.mimetype(),
//                 name: description.name(),
//                 size: description.size() ?? 0,
//                 uri: description.source().url(),
//               );
//             }
//             break;
//           case 'm.emote':
//             break;
//           case 'm.file':
//             FileDesc? description = eventItem.fileDesc();
//             if (description != null) {
//               Map<String, dynamic> metadata = {};
//               if (inReplyTo != null) {
//                 metadata['repliedTo'] = inReplyTo;
//               }
//               if (reactions.isNotEmpty) {
//                 metadata['reactions'] = reactions;
//               }
//               return types.FileMessage(
//                 author: author,
//                 createdAt: createdAt,
//                 id: eventId,
//                 metadata: metadata,
//                 mimeType: description.mimetype(),
//                 name: description.name(),
//                 size: description.size() ?? 0,
//                 uri: description.source().url(),
//               );
//             }
//             break;
//           case 'm.image':
//             ImageDesc? description = eventItem.imageDesc();
//             if (description != null) {
//               Map<String, dynamic> metadata = {'base64': ''};
//               if (inReplyTo != null) {
//                 metadata['repliedTo'] = inReplyTo;
//               }
//               if (reactions.isNotEmpty) {
//                 metadata['reactions'] = reactions;
//               }
//               return types.ImageMessage(
//                 author: author,
//                 createdAt: createdAt,
//                 height: description.height()?.toDouble(),
//                 id: eventId,
//                 metadata: metadata,
//                 name: description.name(),
//                 size: description.size() ?? 0,
//                 uri: description.source().url(),
//                 width: description.width()?.toDouble(),
//               );
//             }
//             break;
//           case 'm.location':
//             break;
//           case 'm.notice':
//             TextDesc? description = eventItem.textDesc();
//             if (description != null) {
//               String? formattedBody = description.formattedBody();
//               String body = description.body(); // always exists
//               return types.TextMessage(
//                 author: author,
//                 createdAt: createdAt,
//                 id: eventId,
//                 text: formattedBody ?? body,
//                 metadata: {
//                   'itemType': 'event',
//                   'msgType': eventItem.subType(),
//                   'eventType': eventType,
//                   'messageLength': body.length,
//                 },
//               );
//             }
//             break;
//           case 'm.server_notice':
//             TextDesc? description = eventItem.textDesc();
//             if (description != null) {
//               String? formattedBody = description.formattedBody();
//               String body = description.body(); // always exists
//               return types.TextMessage(
//                 author: author,
//                 createdAt: createdAt,
//                 id: eventId,
//                 text: formattedBody ?? body,
//                 metadata: {
//                   'itemType': 'event',
//                   'eventType': eventType,
//                   'msgType': eventItem.subType(),
//                   'messageLength': body.length,
//                 },
//               );
//             }
//             break;
//           case 'm.text':
//             TextDesc? description = eventItem.textDesc();
//             if (description != null) {
//               String? formattedBody = description.formattedBody();
//               String body = description.body(); // always exists
//               Map<String, dynamic> metadata = {
//                 'messageLength': body.length,
//               };
//               if (inReplyTo != null) {
//                 metadata['repliedTo'] = inReplyTo;
//               }
//               if (reactions.isNotEmpty) {
//                 metadata['reactions'] = reactions;
//               }
//               //check whether string only contains emoji(s).
//               metadata['enlargeEmoji'] = isOnlyEmojis(description.body());
//               return types.TextMessage(
//                 author: author,
//                 createdAt: createdAt,
//                 id: eventId,
//                 metadata: metadata,
//                 text: formattedBody ?? body,
//               );
//             }
//             break;
//           case 'm.video':
//             VideoDesc? description = eventItem.videoDesc();
//             if (description != null) {
//               Map<String, dynamic> metadata = {'base64': ''};
//               if (inReplyTo != null) {
//                 metadata['repliedTo'] = inReplyTo;
//               }
//               if (reactions.isNotEmpty) {
//                 metadata['reactions'] = reactions;
//               }
//               return types.VideoMessage(
//                 author: author,
//                 createdAt: createdAt,
//                 id: eventId,
//                 metadata: metadata,
//                 name: description.name(),
//                 size: description.size() ?? 0,
//                 uri: description.source().url(),
//               );
//             }
//             break;
//           case 'm.key.verification.request':
//             break;
//         }
//         break;
//       case 'm.sticker':
//         ImageDesc? description = eventItem.imageDesc();
//         if (description != null) {
//           Map<String, dynamic> metadata = {
//             'itemType': 'event',
//             'eventType': 'm.sticker',
//             'name': description.name(),
//             'size': description.size() ?? 0,
//             'width': description.width()?.toDouble(),
//             'height': description.height()?.toDouble(),
//             'base64': '',
//           };
//           if (inReplyTo != null) {
//             metadata['repliedTo'] = inReplyTo;
//           }
//           if (reactions.isNotEmpty) {
//             metadata['reactions'] = reactions;
//           }
//           return types.CustomMessage(
//             author: author,
//             createdAt: createdAt,
//             id: eventId,
//             metadata: metadata,
//           );
//         }
//         break;
//     }

//     // should not return null, before we can keep track of index in diff receiver
//     return types.CustomMessage(
//       author: author,
//       createdAt: createdAt,
//       id: eventId,
//       metadata: {
//         'itemType': 'event',
//         'eventType': eventType,
//       },
//     );
//   }

//   List<types.Message> getMessages() {
//     List<types.Message> msgs = _messages.where((x) {
//       if (x.metadata?['itemType'] == 'virtual') {
//         // UnsupportedMessage
//         return false;
//       }
//       return true;
//     }).toList();
//     return msgs;
//   }

//   void _fetchImageContent(String eventId) {
//     _currentRoom!.imageBinary(eventId).then((data) {
//       int index = _messages.indexWhere((x) => x.id == eventId);
//       if (index != -1) {
//         final metadata = _messages[index].metadata ?? {};
//         metadata['base64'] = base64Encode(data.asTypedList());
//         _messages[index] = _messages[index].copyWith(metadata: metadata);
//         if (isLoading.isFalse) {
//           update(['Chat']);
//         }
//       }
//     });
//   }

//   void _fetchAudioContent(String eventId) {
//     _currentRoom!.audioBinary(eventId).then((data) {
//       int index = _messages.indexWhere((x) => x.id == eventId);
//       if (index != -1) {
//         final metadata = _messages[index].metadata ?? {};
//         metadata['base64'] = base64Encode(data.asTypedList());
//         _messages[index] = _messages[index].copyWith(metadata: metadata);
//         if (isLoading.isFalse) {
//           update(['Chat']);
//         }
//       }
//     });
//   }

//   void _fetchVideoContent(String eventId) {
//     _currentRoom!.videoBinary(eventId).then((data) {
//       int index = _messages.indexWhere((x) => x.id == eventId);
//       if (index != -1) {
//         final metadata = _messages[index].metadata ?? {};
//         metadata['base64'] = base64Encode(data.asTypedList());
//         _messages[index] = _messages[index].copyWith(metadata: metadata);
//         if (isLoading.isFalse) {
//           update(['Chat']);
//         }
//       }
//     });
//   }

//   // fetch original content media for reply msg .i.e. text,image,file etc.
//   void _fetchOriginalContent(String originalId, String replyId) {
//     _currentRoom!.getMessage(originalId).then((roomMsg) {
//       // reply is allowed for only EventItem not VirtualItem
//       // user should be able to get original event as RoomMessage
//       RoomEventItem orgEventItem = roomMsg.eventItem()!;
//       String? orgMsgType = orgEventItem.subType();
//       Map<String, dynamic> repliedToContent = {};
//       types.Message? repliedTo;
//       if (orgMsgType == 'm.text') {
//         TextDesc? description = orgEventItem.textDesc();
//         if (description != null) {
//           String body = description.body();
//           repliedToContent = {
//             'content': body,
//             'messageLength': body.length,
//           };
//           repliedTo = types.TextMessage(
//             author: types.User(id: orgEventItem.sender()),
//             id: originalId,
//             createdAt: orgEventItem.originServerTs(),
//             text: body,
//             metadata: repliedToContent,
//           );
//         }
//       } else if (orgMsgType == 'm.image') {
//         ImageDesc? description = orgEventItem.imageDesc();
//         if (description != null) {
//           _currentRoom!.imageBinary(originalId).then((data) {
//             repliedToContent['content'] = base64Encode(data.asTypedList());
//           });
//           repliedTo = types.ImageMessage(
//             author: types.User(id: orgEventItem.sender()),
//             id: originalId,
//             createdAt: orgEventItem.originServerTs(),
//             name: description.name(),
//             size: description.size() ?? 0,
//             uri: description.source().url(),
//             metadata: repliedToContent,
//           );
//         }
//       } else if (orgMsgType == 'm.audio') {
//         AudioDesc? description = orgEventItem.audioDesc();
//         if (description != null) {
//           _currentRoom!.audioBinary(originalId).then((data) {
//             repliedToContent['content'] = base64Encode(data.asTypedList());
//           });
//           repliedTo = types.AudioMessage(
//             author: types.User(id: orgEventItem.sender()),
//             id: originalId,
//             createdAt: orgEventItem.originServerTs(),
//             name: description.name(),
//             duration: Duration(seconds: description.duration() ?? 0),
//             size: description.size() ?? 0,
//             uri: description.source().url(),
//             metadata: repliedToContent,
//           );
//         }
//       } else if (orgMsgType == 'm.video') {
//         VideoDesc? description = orgEventItem.videoDesc();
//         if (description != null) {
//           _currentRoom!.videoBinary(originalId).then((data) {
//             repliedToContent['content'] = base64Encode(data.asTypedList());
//           });
//           repliedTo = types.VideoMessage(
//             author: types.User(id: orgEventItem.sender()),
//             id: originalId,
//             createdAt: orgEventItem.originServerTs(),
//             name: description.name(),
//             size: description.size() ?? 0,
//             uri: description.source().url(),
//             metadata: repliedToContent,
//           );
//         }
//       } else if (orgMsgType == 'm.file') {
//         FileDesc? description = orgEventItem.fileDesc();
//         if (description != null) {
//           repliedToContent = {
//             'content': description.name(),
//           };
//           repliedTo = types.FileMessage(
//             author: types.User(id: orgEventItem.sender()),
//             id: originalId,
//             createdAt: orgEventItem.originServerTs(),
//             name: description.name(),
//             size: description.size() ?? 0,
//             uri: description.source().url(),
//             metadata: repliedToContent,
//           );
//         }
//       } else if (orgMsgType == 'm.sticker') {
//         // user can't do any action about sticker message
//       }
//       int index = _messages.indexWhere((x) => x.id == replyId);
//       if (index != -1 && repliedTo != null) {
//         _messages[index] = _messages[index].copyWith(repliedMessage: repliedTo);
//       }
//       if (isLoading.isFalse) {
//         update(['Chat']);
//       }
//     });
//   }

//   /// Update button state based on text editor.
//   void sendButtonUpdate() {
//     isSendButtonVisible =
//         mentionKey.currentState!.controller!.text.trim().isNotEmpty;
//     update(['chat-input']);
//   }

//   /// Disable button as soon as send button is pressed.
//   void sendButtonDisable() {
//     isSendButtonVisible = !isSendButtonVisible;
//     update(['chat-input']);
//   }

//   Future<bool> typingNotice(bool typing) async {
//     if (_currentRoom == null) {
//       return Future.value(false);
//     }
//     return await _currentRoom!.typingNotice(typing);
//   }

//   void updateEmojiState(types.Message message) {
//     emojiMessageIndex = _messages.indexWhere((x) => x.id == message.id);
//     emojiCurrentId = _messages[emojiMessageIndex].id;
//     if (emojiCurrentId == message.id) {
//       isEmojiContainerVisible = !isEmojiContainerVisible;
//     }

//     if (isEmojiContainerVisible) {
//       authorId = message.author.id;
//     }
//     update(['emoji-reaction']);
//   }

//   

//   void toggleEmojiContainer() {
//     isEmojiContainerVisible = !isEmojiContainerVisible;
//     update(['emoji-reaction']);
//   }

//   Future<void> sendEmojiReaction(String eventId, String emoji) async {
//     await _currentRoom!.sendReaction(eventId, emoji);
//   }

//   Future<void> redactRoomMessage(String eventId) async {
//     await _currentRoom!.redactMessage(eventId, '', null);
//   }
// }
