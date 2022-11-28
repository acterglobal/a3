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
        FileDescription,
        ImageDescription,
        Member,
        RoomMessage,
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
  List<types.Message> messages = [];
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
          if (event.sender() != client.userId().toString()) {
            types.Message? m = await _prepareMessage(event);
            if (m != null) {
              _insertMessage(messages.length, m);
              if (isLoading.isFalse) {
                update(['Chat']);
              }
              if (event.msgtype() == 'm.image') {
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
      messages.clear();
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
      _stream = _currentRoom!.timeline();
      // event handler from paginate
      _diffSubscription = _stream?.diffRx().listen((event) async {
        switch (event.action()) {
          case 'Replace':
            List<RoomMessage> values = event.values()!.toList();
            for (RoomMessage msg in values) {
              types.Message? m = await _prepareMessage(msg);
              if (m != null) {
                _insertMessage(0, m);
                if (isLoading.isFalse) {
                  update(['Chat']);
                }
                if (msg.msgtype() == 'm.image') {
                  _fetchMessageContent(m.id);
                }
              }
            }
            break;
          case 'InsertAt':
            int index = event.index()!;
            RoomMessage? value = event.value();
            if (value == null) {
              break; // message decryption may be failed
            }
            types.Message? m = await _prepareMessage(value);
            if (m != null) {
              _insertMessage(messages.length - index, m);
              if (isLoading.isFalse) {
                update(['Chat']);
              }
              if (value.msgtype() == 'm.image') {
                _fetchMessageContent(m.id);
              }
            }
            break;
          case 'UpdateAt':
            int index = event.index()!;
            RoomMessage? value = event.value();
            if (value == null) {
              break; // message decryption may be failed
            }
            types.Message? m = await _prepareMessage(value);
            if (m != null) {
              _updateMessage(messages.length - index, m);
              if (isLoading.isFalse) {
                update(['Chat']);
              }
              if (value.msgtype() == 'm.image') {
                _fetchMessageContent(m.id);
              }
            }
            break;
          case 'Push':
            RoomMessage? value = event.value();
            if (value == null) {
              break; // message decryption may be failed
            }
            types.Message? m = await _prepareMessage(value);
            if (m != null) {
              _insertMessage(0, m);
              if (isLoading.isFalse) {
                update(['Chat']);
              }
              String msgType = value.msgtype();
              debugPrint('msgType - $msgType');
              if (value.msgtype() == 'm.image') {
                _fetchMessageContent(m.id);
              }
            }
            break;
          case 'RemoveAt':
            int index = event.index()!;
            messages.removeAt(messages.length - index);
            if (isLoading.isFalse) {
              update(['Chat']);
            }
            break;
          case 'Move':
            int oldIndex = event.oldIndex()!;
            int newIndex = event.newIndex()!;
            types.Message m = messages.removeAt(messages.length - oldIndex);
            messages.insert(messages.length - newIndex, m);
            if (isLoading.isFalse) {
              update(['Chat']);
            }
            break;
          case 'Pop':
            messages.removeLast();
            if (isLoading.isFalse) {
              update(['Chat']);
            }
            break;
          case 'Clear':
            messages.clear();
            if (isLoading.isFalse) {
              update(['Chat']);
            }
            break;
        }
      });
      bool hasMore = await _stream!.paginateBackwards(10);
      debugPrint('backward pagination has more: $hasMore');
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
    final idx = messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = (messages[idx] as types.TextMessage).copyWith(
      previewData: previewData,
    );

    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      messages[idx] = updatedMessage;
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
      messages.insert(0, message);
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
    List<String> seenByList = receiptController.getSeenByList(
      _currentRoom!.getRoomId(),
      m.createdAt!,
    );
    if (m.author.id == client.userId().toString()) {
      types.Status status = seenByList.length < activeMembers.length
          ? types.Status.delivered
          : types.Status.seen;
      messages.insert(index, m.copyWith(showStatus: true, status: status));
    } else {
      messages.insert(index, m);
    }
  }

  void _updateMessage(int index, types.Message m) {
    var receiptController = Get.find<ReceiptController>();
    List<String> seenByList = receiptController.getSeenByList(
      _currentRoom!.getRoomId(),
      m.createdAt!,
    );
    if (m.author.id == client.userId().toString()) {
      types.Status status = seenByList.length < activeMembers.length
          ? types.Status.delivered
          : types.Status.seen;
      messages[index] = m.copyWith(showStatus: true, status: status);
    } else {
      messages[index] = m;
    }
  }

  Future<types.Message?> _prepareMessage(RoomMessage message) async {
    String msgtype = message.msgtype();
    String sender = message.sender();
    var author = types.User(id: sender, firstName: simplifyUserId(sender));
    int? createdAt = message.originServerTs(); // in milliseconds
    String eventId = message.eventId();

    if (msgtype == 'm.audio') {
    } else if (msgtype == 'm.emote') {
    } else if (msgtype == 'm.file') {
      FileDescription? description = message.fileDescription();
      if (description != null) {
        return types.FileMessage(
          author: author,
          createdAt: createdAt,
          id: eventId,
          name: description.name(),
          size: description.size() ?? 0,
          uri: '',
        );
      }
    } else if (msgtype == 'm.image') {
      ImageDescription? description = message.imageDescription();
      if (description != null) {
        final path = (await getApplicationDocumentsDirectory()).path;
        return types.ImageMessage(
          author: author,
          createdAt: createdAt,
          height: description.height()?.toDouble(),
          id: eventId,
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
      return types.TextMessage(
        author: author,
        createdAt: createdAt,
        id: eventId,
        text: message.formattedBody() ?? message.body(),
        metadata: {
          'messageLength': message.body().length,
        },
      );
    } else if (msgtype == 'm.video') {
    } else if (msgtype == 'm.key.verification.request') {}
    return null;
  }

  void _fetchMessageContent(String eventId) {
    _currentRoom!.imageBinary(eventId).then((data) {
      int idx = messages.indexWhere((x) => x.id == eventId);
      if (idx != -1) {
        final base64String = base64Encode(data.asTypedList());
        messages[idx] = messages[idx].copyWith(
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
    emojiMessageIndex = messages.indexWhere(
      (element) => element.id == message.id,
    );
    emojiCurrentId = messages[emojiMessageIndex].id;
    if (emojiCurrentId == message.id) {
      isEmojiContainerVisible = !isEmojiContainerVisible;
    }
    update(['emoji-reaction']);
  }

  void toggleEmojiContainer() {
    isEmojiContainerVisible = !isEmojiContainerVisible;
    update(['emoji-reaction']);
  }
}
