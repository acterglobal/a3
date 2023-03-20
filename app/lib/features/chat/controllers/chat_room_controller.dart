import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/controllers/receipt_controller.dart';
import 'package:acter/features/chat/pages/image_selection_page.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show
        Client,
        Conversation,
        FfiBufferUint8,
        FileDesc,
        ImageDesc,
        Member,
        RoomEventItem,
        RoomMessage,
        RoomVirtualItem,
        TextDesc,
        TimelineDiff,
        TimelineStream,
        UserProfile;
import 'package:file_picker/file_picker.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:get/get.dart';
import 'package:mime/mime.dart';
import 'package:open_app_file/open_app_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatRoomController extends GetxController {
  Client client;
  late String userId;
  final List<types.Message> _messages = [];
  List<types.User> typingUsers = [];
  TimelineStream? _stream;
  RxBool isLoading = false.obs;
  int _page = 0;
  Conversation? _currentRoom;
  final bool _isDesktop = !(Platform.isAndroid || Platform.isIOS);
  RxBool isEmojiVisible = false.obs;
  RxBool isAttachmentVisible = false.obs;
  FocusNode focusNode = FocusNode();
  GlobalKey<FlutterMentionsState> mentionKey =
      GlobalKey<FlutterMentionsState>();
  bool isSendButtonVisible = false;
  bool isEmojiContainerVisible = false;
  final List<PlatformFile> _imageFileList = [];
  List<Member> activeMembers = [];
  Map<String, String> messageTextMapMarkDown = {};
  Map<String, String> messageTextMapHtml = {};
  final Map<String, Future<FfiBufferUint8>> _userAvatars = {};
  final Map<String, String> _userNames = {};
  List<Map<String, dynamic>> mentionList = [];
  StreamSubscription<TimelineDiff>? _diffSubscription;
  StreamSubscription<RoomMessage>? _messageSubscription;
  int emojiMessageIndex = 0;
  String? emojiCurrentId;
  String? authorId;
  bool showReplyView = false;
  Widget? replyMessageWidget;
  types.Message? repliedToMessage;

  ChatRoomController({required this.client}) : super();

  @override
  void onInit() {
    super.onInit();
    userId = client.userId().toString();
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        isEmojiVisible.value = false;
        isAttachmentVisible.value = false;
      }
    });

    _messageSubscription = client.incomingMessageRx()?.listen((event) {
      // the latest message is dealt in convo receiver of ChatListController
      // here manage only its message history
      if (_currentRoom == null) {
        return;
      }
      // filter only message of this room
      if (event.roomId() != _currentRoom!.getRoomId()) {
        return;
      }
      // filter only message from other not me
      // it is processed in handleSendPressed
      var m = _prepareMessage(event);
      if (m is types.UnsupportedMessage) {
        return;
      }
      int index = _messages.indexWhere((msg) => m.id == msg.id);
      if (index == -1) {
        _insertMessage(m);
      } else {
        // update event may be fetched prior to insert event
        _updateMessage(m, index);
      }
      RoomEventItem? eventItem = event.eventItem();
      if (eventItem != null) {
        if (eventItem.sender() != client.userId().toString()) {
          if (isLoading.isFalse) {
            update(['Chat']);
          }
          if (eventItem.subType() == 'm.image') {
            _fetchMessageContent(m.id);
          }
        }
        if (m.metadata != null && m.metadata!.containsKey('repliedTo')) {
          _fetchOriginalContent(m.metadata?['repliedTo'], m.id);
        }
      }
    });
  }

  @override
  void onClose() {
    focusNode.removeListener(() {});
    _diffSubscription?.cancel();
    _messageSubscription?.cancel();

    super.onClose();
  }

  // get the timeline of room
  Future<void> setCurrentRoom(Conversation? convoRoom) async {
    var receiptController = Get.find<ReceiptController>();
    if (convoRoom == null) {
      _messages.clear();
      typingUsers.clear();
      activeMembers.clear();
      mentionList.clear();
      _diffSubscription?.cancel();
      _stream = null;
      _page = 0;
      if (_currentRoom != null) {
        receiptController.unloadRoom(_currentRoom!);
      }
      _currentRoom = null;
      return;
    }
    _currentRoom = convoRoom;
    update(['room-profile']);
    isLoading.value = true;
    activeMembers = (await convoRoom.activeMembers()).toList();
    update(['active-members']);
    _fetchUserProfiles();
    if (_currentRoom == null) {
      // user may close chat screen before long loading completed
      isLoading.value = false;
      return;
    }
    _stream = await _currentRoom!.timelineStream();
    // event handler from paginate
    _diffSubscription = _stream?.diffRx().listen((event) {
      switch (event.action()) {
        case 'Replace':
          debugPrint('chat room message replace');
          List<RoomMessage> values = event.values()!.toList();
          for (RoomMessage msg in values) {
            var m = _prepareMessage(msg);
            if (m is types.UnsupportedMessage) {
              continue;
            }
            int index = _messages.indexWhere((msg) => m.id == msg.id);
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
              if (isLoading.isFalse) {
                update(['Chat']);
              }
              if (eventItem.subType() == 'm.image') {
                _fetchMessageContent(m.id);
              }
            }
          }
          break;
        case 'InsertAt':
          debugPrint('chat room message insert at');
          RoomMessage value = event.value()!;
          var m = _prepareMessage(value);
          if (m is types.UnsupportedMessage) {
            break;
          }
          int index = _messages.indexWhere((msg) => m.id == msg.id);
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
            if (isLoading.isFalse) {
              update(['Chat']);
            }
            if (eventItem.subType() == 'm.image') {
              _fetchMessageContent(m.id);
            }
          }
          break;
        case 'UpdateAt':
          debugPrint('chat room message update at');
          RoomMessage value = event.value()!;
          var m = _prepareMessage(value);
          if (m is types.UnsupportedMessage) {
            break;
          }
          int index = _messages.indexWhere((msg) => m.id == msg.id);
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
            if (isLoading.isFalse) {
              update(['Chat']);
            }
            if (eventItem.subType() == 'm.image') {
              _fetchMessageContent(m.id);
            }
          }
          break;
        case 'Push':
          debugPrint('chat room message push');
          RoomMessage value = event.value()!;
          var m = _prepareMessage(value);
          if (m is types.UnsupportedMessage) {
            break;
          }
          _messages.insert(0, m);
          if (m.metadata != null && m.metadata!.containsKey('repliedTo')) {
            _fetchOriginalContent(m.metadata?['repliedTo'], m.id);
          }
          RoomEventItem? eventItem = value.eventItem();
          if (eventItem != null) {
            if (isLoading.isFalse) {
              update(['Chat']);
            }
            if (eventItem.subType() == 'm.image') {
              _fetchMessageContent(m.id);
            }
          }
          break;
        case 'RemoveAt':
          int index = event.index()!;
          _messages.removeAt(_messages.length - 1 - index);
          if (isLoading.isFalse) {
            update(['Chat']);
          }
          break;
        case 'Move':
          int oldIndex = event.oldIndex()!;
          int newIndex = event.newIndex()!;
          int i = _messages.length - newIndex;
          if (oldIndex < newIndex) {
            i += 1;
          }
          var m = _messages.removeAt(_messages.length - 1 - oldIndex);
          if (m is types.UnsupportedMessage) {
            break;
          }
          _messages.insert(i, m);
          if (m.metadata != null && m.metadata!.containsKey('repliedTo')) {
            _fetchOriginalContent(m.metadata?['repliedTo'], m.id);
          }
          if (isLoading.isFalse) {
            update(['Chat']);
          }
          break;
        case 'Pop':
          _messages.removeLast();
          if (isLoading.isFalse) {
            update(['Chat']);
          }
          break;
        case 'Clear':
          _messages.clear();
          if (isLoading.isFalse) {
            update(['Chat']);
          }
          break;
      }
    });

    if (_currentRoom == null) {
      // user may close chat screen before long loading completed
      isLoading.value = false;
      return;
    }
    bool hasMore = true;
    do {
      hasMore = await _stream!.paginateBackwards(10);
      // wait for diff rx to be finished
      sleep(const Duration(milliseconds: 500));
    } while (hasMore && _messages.length < 10);
    // load receipt status of room
    var receipts = (await convoRoom.userReceipts()).toList();
    if (_currentRoom == null) {
      // user may close chat screen before long loading completed
      isLoading.value = false;
      return;
    }
    receiptController.loadRoom(convoRoom, receipts);
    isLoading.value = false;
  }

  String? currentRoomId() {
    return _currentRoom?.getRoomId();
  }

  Future<void> _fetchUserProfiles() async {
    Map<String, Future<FfiBufferUint8>> avatars = {};
    Map<String, String> names = {};
    List<String> ids = [];
    List<Map<String, dynamic>> mentionRecords = [];
    for (int i = 0; i < activeMembers.length; i++) {
      String userId = activeMembers[i].userId();
      ids.add('user-profile-$userId');
      UserProfile profile = await activeMembers[i].getProfile();
      Map<String, dynamic> record = {};
      if (profile.hasAvatar()) {
        avatars[userId] = profile.getThumbnail(62, 60);
        record['avatar'] = avatars[userId];
      }
      String? name = profile.getDisplayName();
      record['display'] = name;
      record['link'] = userId;
      if (name != null) {
        names[userId] = name;
      }
      mentionRecords.add(record);
      if (i % 3 == 0 || i == activeMembers.length - 1) {
        _userAvatars.addAll(avatars);
        _userNames.addAll(names);
        mentionList.addAll(mentionRecords);
        mentionRecords.clear();
        update(['chat-input']);
        update(ids);
        avatars.clear();
        names.clear();
        ids.clear();
      }
    }
  }

  Future<FfiBufferUint8>? getUserAvatar(String userId) {
    return _userAvatars.containsKey(userId) ? _userAvatars[userId] : null;
  }

  String? getUserName(String userId) {
    return _userNames.containsKey(userId) ? _userNames[userId] : null;
  }

  //preview message link
  void handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final index = _messages.indexWhere((x) => x.id == message.id);
    final updatedMessage = (_messages[index] as types.TextMessage).copyWith(
      previewData: previewData,
    );

    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      _messages[index] = updatedMessage;
      update(['Chat']);
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
    await _currentRoom!.typingNotice(false);
    if (repliedToMessage != null) {
      await _currentRoom!.sendTextReply(
        markdownMessage,
        repliedToMessage!.id,
        null,
      );
      repliedToMessage = null;
      replyMessageWidget = null;
      showReplyView = false;
      update(['chat-input']);
    } else {
      await _currentRoom!.sendFormattedMessage(markdownMessage);
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
    if (repliedToMessage != null) {
      await _currentRoom!.sendImageReply(
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
      replyMessageWidget = null;
      showReplyView = false;
      update(['chat-input']);
    } else {
      await _currentRoom!.sendImageMessage(
        path,
        name,
        mimeType!,
        bytes.length,
        image.width,
        image.height,
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
    if (repliedToMessage != null) {
      await _currentRoom!.sendImageReply(
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
      replyMessageWidget = null;
      showReplyView = false;
      update(['chat-input']);
    } else {
      await _currentRoom!.sendImageMessage(
        path,
        name,
        mimeType!,
        bytes.length,
        image.width,
        image.height,
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
    if (repliedToMessage != null) {
      await _currentRoom!.sendFileReply(
        path,
        name,
        mimeType!,
        result.files.single.size,
        repliedToMessage!.id,
        null,
      );
      repliedToMessage = null;
      replyMessageWidget = null;
      showReplyView = false;
      update(['chat-input']);
    } else {
      await _currentRoom!.sendFileMessage(
        path,
        name,
        mimeType!,
        result.files.single.size,
      );
    }
  }

  Future<void> handleMessageTap(
    BuildContext context,
    types.Message message,
  ) async {
    if (message is types.FileMessage) {
      String filePath = await _currentRoom!.filePath(message.id);
      if (filePath.isEmpty) {
        Directory? rootPath = await getTemporaryDirectory();
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
          await _currentRoom!.saveFile(message.id, dirPath);
        }
      } else {
        final result = await OpenAppFile.open(filePath);
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

  //Pagination Control
  Future<void> handleEndReached() async {
    bool hasMore = await _stream!.paginateBackwards(10);
    debugPrint('backward pagination has more: $hasMore');
    _page = _page + 1;
    update(['Chat']);
  }

  void _insertMessage(types.Message m) {
    if (m is! types.UnsupportedMessage) {
      var receiptController = Get.find<ReceiptController>();
      List<String> seenByList = receiptController.getSeenByList(
        _currentRoom!.getRoomId(),
        m.createdAt!,
      );
      if (m.author.id == client.userId().toString()) {
        types.Status status = seenByList.isEmpty
            ? types.Status.sent
            : seenByList.length < activeMembers.length
                ? types.Status.delivered
                : types.Status.seen;
        _messages.add(m.copyWith(showStatus: true, status: status));
        return;
      }
    }
    _messages.add(m);
  }

  void _updateMessage(types.Message m, int index) {
    if (m is! types.UnsupportedMessage) {
      var receiptController = Get.find<ReceiptController>();
      List<String> seenByList = receiptController.getSeenByList(
        _currentRoom!.getRoomId(),
        m.createdAt!,
      );
      if (m.author.id == client.userId().toString()) {
        types.Status status = seenByList.isEmpty
            ? types.Status.sent
            : seenByList.length < activeMembers.length
                ? types.Status.delivered
                : types.Status.seen;
        _messages[index] = m.copyWith(showStatus: true, status: status);
        return;
      }
    }
    _messages[index] = m;
  }

  types.Message _prepareMessage(RoomMessage message) {
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
                name: description.name(),
                size: description.size() ?? 0,
                uri: '',
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
              metadata['base64'] = '';
              return types.ImageMessage(
                author: author,
                createdAt: createdAt,
                height: description.height()?.toDouble(),
                id: eventId,
                metadata: metadata,
                name: description.name(),
                size: description.size() ?? 0,
                uri: '',
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
              if (isOnlyEmojis(description.body())) {
                metadata['enlargeEmoji'] = true;
              } else {
                metadata['enlargeEmoji'] = false;
              }
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
          metadata['base64'] = '';
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

  List<types.Message> getMessages() {
    List<types.Message> msgs = _messages.where((x) {
      if (x.metadata?['itemType'] == 'virtual') {
        // UnsupportedMessage
        return false;
      }
      return true;
    }).toList();
    return msgs;
  }

  void _fetchMessageContent(String eventId) {
    _currentRoom!.imageBinary(eventId).then((data) {
      int index = _messages.indexWhere((x) => x.id == eventId);
      if (index != -1) {
        final metadata = _messages[index].metadata ?? {};
        metadata['base64'] = base64Encode(data.asTypedList());
        _messages[index] = _messages[index].copyWith(metadata: metadata);
        if (isLoading.isFalse) {
          update(['Chat']);
        }
      }
    });
  }

  // fetch original content media for reply msg .i.e. text,image,file etc.
  void _fetchOriginalContent(String originalId, String replyId) {
    _currentRoom!.getMessage(originalId).then((roomMsg) {
      // reply is allowed for only EventItem not VirtualItem
      // user should be able to get original event as RoomMessage
      RoomEventItem orgEventItem = roomMsg.eventItem()!;
      String? orgMsgType = orgEventItem.subType();
      Map<String, dynamic> repliedToContent = {};
      types.Message? repliedTo;
      if (orgMsgType == 'm.text') {
        repliedToContent = {
          'content': orgEventItem.textDesc()!.body(),
          'messageLength': orgEventItem.textDesc()!.body().length,
        };
        repliedTo = types.TextMessage(
          author: types.User(id: orgEventItem.sender()),
          id: originalId,
          createdAt: orgEventItem.originServerTs(),
          text: orgEventItem.textDesc()!.body(),
          metadata: repliedToContent,
        );
      } else if (orgMsgType == 'm.image') {
        _currentRoom!.imageBinary(originalId).then((data) {
          repliedToContent['content'] = base64Encode(data.asTypedList());
        });
        repliedTo = types.ImageMessage(
          author: types.User(id: orgEventItem.sender()),
          id: originalId,
          createdAt: orgEventItem.originServerTs(),
          name: orgEventItem.imageDesc()!.name(),
          size: orgEventItem.imageDesc()!.size()!,
          uri: '',
          metadata: repliedToContent,
        );
      } else if (orgMsgType == 'm.file') {
        repliedToContent = {
          'content': orgEventItem.fileDesc()!.name(),
        };
        repliedTo = types.FileMessage(
          author: types.User(id: orgEventItem.sender()),
          id: originalId,
          createdAt: orgEventItem.originServerTs(),
          name: orgEventItem.fileDesc()!.name(),
          size: orgEventItem.fileDesc()!.size()!,
          uri: '',
          metadata: repliedToContent,
        );
      } else if (orgMsgType == 'm.sticker') {
        // user can't do any action about sticker message
      }
      int index = _messages.indexWhere((x) => x.id == replyId);
      if (index != -1) {
        _messages[index] = _messages[index].copyWith(repliedMessage: repliedTo);
      }
      if (isLoading.isFalse) {
        update(['Chat']);
      }
    });
  }

  /// Update button state based on text editor.
  void sendButtonUpdate() {
    isSendButtonVisible =
        mentionKey.currentState!.controller!.text.trim().isNotEmpty;
    update(['chat-input']);
  }

  /// Disable button as soon as send button is pressed.
  void sendButtonDisable() {
    isSendButtonVisible = !isSendButtonVisible;
    update(['chat-input']);
  }

  Future<bool> typingNotice(bool typing) async {
    if (_currentRoom == null) {
      return Future.value(false);
    }
    return await _currentRoom!.typingNotice(typing);
  }

  void updateEmojiState(types.Message message) {
    emojiMessageIndex = _messages.indexWhere((x) => x.id == message.id);
    emojiCurrentId = _messages[emojiMessageIndex].id;
    if (emojiCurrentId == message.id) {
      isEmojiContainerVisible = !isEmojiContainerVisible;
    }

    if (isEmojiContainerVisible) {
      authorId = message.author.id;
    }
    update(['emoji-reaction']);
  }

  bool isAuthor() {
    return client.userId().toString() == authorId;
  }

  void toggleEmojiContainer() {
    isEmojiContainerVisible = !isEmojiContainerVisible;
    update(['emoji-reaction']);
  }

  Future<void> sendEmojiReaction(String eventId, String emoji) async {
    await _currentRoom!.sendReaction(eventId, emoji);
  }

  Future<void> redactRoomMessage(String eventId) async {
    await _currentRoom!.redactMessage(eventId, '', null);
  }
}
