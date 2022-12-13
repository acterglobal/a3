import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:effektio/controllers/receipt_controller.dart';
import 'package:effektio/screens/HomeScreens/chat/ImageSelectionScreen.dart';
import 'package:effektio/widgets/AppCommon.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show
        Client,
        Conversation,
        FfiBufferUint8,
        FileDesc,
        ImageDesc,
        Member,
        RoomEventItem,
        RoomMessage,
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
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatRoomController extends GetxController {
  Client client;
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
  final List<XFile> _imageFileList = [];
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

  ChatRoomController({required this.client}) : super();

  @override
  void onInit() {
    super.onInit();

    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        isEmojiVisible.value = false;
        isAttachmentVisible.value = false;
      }
    });

    _messageSubscription = client.incomingMessageRx()?.listen((event) async {
      // the latest message is dealt in convo receiver of ChatListController
      // here manage only its message history
      if (_currentRoom != null) {
        // filter only message of this room
        if (event.roomId() == _currentRoom!.getRoomId()) {
          // filter only message from other not me
          // it is processed in handleSendPressed
          types.Message m = await _prepareMessage(event);
          _insertMessage(_messages.length, m);
          RoomEventItem? eventItem = event.eventItem();
          if (eventItem != null) {
            if (eventItem.sender() != client.userId().toString()) {
              if (isLoading.isFalse) {
                update(['Chat']);
              }
              if (eventItem.msgtype() == 'm.image') {
                _fetchMessageContent(m.id);
              }
            }
          }
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

  //get the timeline of room
  Future<void> setCurrentRoom(Conversation? convoRoom) async {
    if (convoRoom == null) {
      _messages.clear();
      typingUsers.clear();
      activeMembers.clear();
      mentionList.clear();
      _diffSubscription?.cancel();
      _stream = null;
      _page = 0;
      _currentRoom = null;
    } else {
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
      _diffSubscription = _stream?.diffRx().listen((event) async {
        switch (event.action()) {
          case 'Replace':
            debugPrint('chat room message replace');
            List<RoomMessage> values = event.values()!.toList();
            for (RoomMessage msg in values) {
              types.Message m = await _prepareMessage(msg);
              _insertMessage(0, m);
              RoomEventItem? eventItem = msg.eventItem();
              if (eventItem != null) {
                if (isLoading.isFalse) {
                  update(['Chat']);
                }
                if (eventItem.msgtype() == 'm.image') {
                  _fetchMessageContent(m.id);
                }
              }
            }
            break;
          case 'InsertAt':
            debugPrint('chat room message insert at');
            int index = event.index()!;
            RoomMessage value = event.value()!;
            types.Message m = await _prepareMessage(value);
            _insertMessage(_messages.length - index, m);
            RoomEventItem? eventItem = value.eventItem();
            if (eventItem != null) {
              if (isLoading.isFalse) {
                update(['Chat']);
              }
              if (eventItem.msgtype() == 'm.image') {
                _fetchMessageContent(m.id);
              }
            }
            break;
          case 'UpdateAt':
            debugPrint('chat room message update at');
            int index = event.index()!;
            RoomMessage value = event.value()!;
            types.Message m = await _prepareMessage(value);
            _updateMessage(_messages.length - index, m);
            RoomEventItem? eventItem = value.eventItem();
            if (eventItem != null) {
              if (isLoading.isFalse) {
                update(['Chat']);
              }
              if (eventItem.msgtype() == 'm.image') {
                _fetchMessageContent(m.id);
              }
            }
            break;
          case 'Push':
            debugPrint('chat room message push');
            RoomMessage value = event.value()!;
            types.Message m = await _prepareMessage(value);
            _insertMessage(0, m);
            RoomEventItem? eventItem = value.eventItem();
            if (eventItem != null) {
              if (isLoading.isFalse) {
                update(['Chat']);
              }
              if (eventItem.msgtype() == 'm.image') {
                _fetchMessageContent(m.id);
              }
            }
            break;
          case 'RemoveAt':
            int index = event.index()!;
            _messages.removeAt(_messages.length - index);
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
            types.Message m = _messages.removeAt(_messages.length - oldIndex);
            _messages.insert(i, m);
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
      bool hasMore = await _stream!.paginateBackwards(10);
      debugPrint('backward pagination has more: $hasMore');
      if (hasMore && _messages.length < 10) {
        await _stream!.paginateBackwards(10);
      }
      // load receipt status of room
      var receiptController = Get.find<ReceiptController>();
      var receipts = (await convoRoom.userReceipts()).toList();
      if (_currentRoom == null) {
        // user may close chat screen before long loading completed
        isLoading.value = false;
        return;
      }
      receiptController.loadRoom(convoRoom.getRoomId(), receipts);
      isLoading.value = false;
    }
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
        avatars[userId] = profile.getAvatar();
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
    await _currentRoom!.sendFormattedMessage(markdownMessage);
  }

  Future<void> handleMultipleImageSelection(
    BuildContext context,
    String roomName,
  ) async {
    _imageFileList.clear();
    final result = await ImagePicker().pickMultiImage(
      imageQuality: 70,
      maxWidth: 1440,
    );
    if (result != null) {
      _imageFileList.addAll(result);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageSelection(
            imageList: _imageFileList,
            roomName: roomName,
          ),
        ),
      );
    }
  }

  Future<void> sendImage(XFile? result) async {
    if (result != null) {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);
      final mimeType = lookupMimeType(result.path);
      await _currentRoom!.sendImageMessage(
        result.path,
        result.name,
        mimeType!,
        bytes.length,
        image.width,
        image.height,
      );
    }
  }

  //image selection
  Future<void> handleImageSelection(BuildContext context) async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);
      final mimeType = lookupMimeType(result.path);
      var eventId = await _currentRoom!.sendImageMessage(
        result.path,
        result.name,
        mimeType!,
        bytes.length,
        image.width,
        image.height,
      );

      // i am sending message
      final message = types.ImageMessage(
        author: types.User(id: client.userId().toString()),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        height: image.height.toDouble(),
        id: eventId,
        name: result.name,
        size: bytes.length,
        uri: result.path,
        width: image.width.toDouble(),
      );
      Navigator.pop(context);
      _messages.insert(0, message);
      update(['Chat']);
    }
  }

  //file selection
  Future<void> handleFileSelection(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );
    if (result != null && result.files.single.path != null) {
      final mimeType = lookupMimeType(result.files.single.path!);
      await _currentRoom!.sendFileMessage(
        result.files.single.path!,
        result.files.single.name,
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
        final result = await OpenFile.open(filePath);
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

  void _insertMessage(int index, types.Message m) {
    var receiptController = Get.find<ReceiptController>();
    if (m.type != types.MessageType.unsupported &&
        m.type != types.MessageType.custom) {
      List<String> seenByList = receiptController.getSeenByList(
        _currentRoom!.getRoomId(),
        m.createdAt!,
      );
      if (m.author.id == client.userId().toString()) {
        types.Status status = seenByList.length < activeMembers.length
            ? types.Status.delivered
            : types.Status.seen;
        _messages.insert(index, m.copyWith(showStatus: true, status: status));
        return;
      }
    }
    _messages.insert(index, m);
  }

  void _updateMessage(int index, types.Message m) {
    var receiptController = Get.find<ReceiptController>();
    if (m.type != types.MessageType.unsupported &&
        m.type != types.MessageType.custom) {
      List<String> seenByList = receiptController.getSeenByList(
        _currentRoom!.getRoomId(),
        m.createdAt!,
      );
      if (m.author.id == client.userId().toString()) {
        types.Status status = seenByList.length < activeMembers.length
            ? types.Status.delivered
            : types.Status.seen;
        _messages[index] = m.copyWith(showStatus: true, status: status);
        return;
      }
    }
    _messages[index] = m;
  }

  Future<types.Message> _prepareMessage(RoomMessage message) async {
    RoomEventItem? eventItem = message.eventItem();
    if (eventItem == null) {
      // should not return null, before we can keep track of index in diff receiver
      return types.UnsupportedMessage(
        author: types.User(id: client.userId().toString()),
        id: UniqueKey().toString(),
        metadata: const {
          'itemType': 'virtual',
        },
      );
    }

    String? msgtype = eventItem.msgtype();
    String sender = eventItem.sender();
    var author = types.User(id: sender, firstName: simplifyUserId(sender));
    int? createdAt = eventItem.originServerTs(); // in milliseconds
    String eventId = eventItem.eventId();

    Map<String, dynamic> reactions = {};
    for (var key in eventItem.reactionKeys()) {
      String k = key.toDartString();
      reactions[k] = eventItem.reactionDesc(k);
    }

    if (msgtype == 'm.audio') {
    } else if (msgtype == 'm.emote') {
    } else if (msgtype == 'm.file') {
      FileDesc? description = eventItem.fileDesc();
      if (description != null) {
        Map<String, dynamic> metadata = {};
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
    } else if (msgtype == 'm.image') {
      ImageDesc? description = eventItem.imageDesc();
      if (description != null) {
        Map<String, dynamic> metadata = {};
        if (reactions.isNotEmpty) {
          metadata['reactions'] = reactions;
        }
        // this is added to get local path of fetched image for previewing purposes (not yet implemented).
        final path = (await getApplicationDocumentsDirectory()).path;
        return types.ImageMessage(
          author: author,
          createdAt: createdAt,
          height: description.height()?.toDouble(),
          id: eventId,
          metadata: metadata,
          name: description.name(),
          size: description.size() ?? 0,
          uri: path + description.name(),
          width: description.width()?.toDouble(),
        );
      }
    } else if (msgtype == 'm.location') {
    } else if (msgtype == 'm.notice') {
    } else if (msgtype == 'm.server_notice') {
    } else if (msgtype == 'm.text') {
      TextDesc? description = eventItem.textDesc();
      String? formattedBody = description!.formattedBody();
      String body = description.body(); // always exists
      Map<String, dynamic> metadata = {
        'messageLength': body.length,
      };
      if (reactions.isNotEmpty) {
        metadata['reactions'] = reactions;
      }
      return types.TextMessage(
        author: author,
        createdAt: createdAt,
        id: eventId,
        metadata: metadata,
        text: formattedBody ?? body,
      );
    } else if (msgtype == 'm.video') {
    } else if (msgtype == 'm.key.verification.request') {}

    // should not return null, before we can keep track of index in diff receiver
    return types.CustomMessage(
      author: author,
      createdAt: createdAt,
      id: eventId,
      metadata: {
        'itemType': 'event',
        'itemContentType': eventItem.itemContentType(),
      },
    );
  }

  List<types.Message> getMessages() {
    List<types.Message> msgs = _messages.where((x) {
      if (x.metadata?['itemType'] == 'virtual') {
        // UnsupportedMessage
        return false;
      }
      if (x.metadata?['itemType'] == 'event') {
        // CustomMessage
        if (x.metadata?['itemContentType'] == 'RedactedMessage') {
          return false; // it cannot be placed as independent entry on msg list
        }
        if (x.metadata?['itemContentType'] == 'FailedToParseMessageLike') {
          return false; // it cannot be placed as independent entry on msg list
        }
        if (x.metadata?['itemContentType'] == 'FailedToParseState') {
          return false; // it cannot be placed as independent entry on msg list
        }
      }
      return true;
    }).toList();
    return msgs;
  }

  void _fetchMessageContent(String eventId) {
    _currentRoom!.imageBinary(eventId).then((data) {
      int index = _messages.indexWhere((x) => x.id == eventId);
      if (index != -1) {
        final base64String = base64Encode(data.asTypedList());
        _messages[index] = _messages[index].copyWith(
          metadata: {
            'base64': base64String,
          },
        );
        if (isLoading.isFalse) {
          update(['Chat']);
        }
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
}
