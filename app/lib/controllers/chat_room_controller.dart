import 'dart:async';
import 'dart:io';

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
  final List<XFile> _imageFileList = [];
  List<Map<String, dynamic>> activeMembers = [];
  Map<String, String> messageTextMapMarkDown = {};
  Map<String, String> messageTextMapHtml = {};
  StreamSubscription<RoomMessage>? _messageSubscription;
  Future<FfiBufferUint8>? roomAvatar;
  String? roomName;

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

    _messageSubscription = client.incomingMessageRx()?.listen((event) {
      // the latest message is dealt in convo receiver of ChatListController
      // here manage only its message history
      if (_currentRoom != null) {
        // filter only message of this room
        if (event.roomId() == _currentRoom!.getRoomId()) {
          // filter only message from other not me
          // it is processed in handleSendPressed
          if (event.sender() != client.userId().toString()) {
            _loadMessage(event);
            update(['Chat']);
          }
        }
      }
    });
  }

  @override
  void onClose() {
    focusNode.removeListener(() {});
    _messageSubscription?.cancel();

    super.onClose();
  }

  //get the timeline of room
  Future<void> setCurrentRoom(Conversation? convoRoom) async {
    if (convoRoom == null) {
      messages.clear();
      typingUsers.clear();
      activeMembers.clear();
      _stream = null;
      _page = 0;
      _currentRoom = null;
      roomAvatar = null;
      roomName = null;
    } else {
      _currentRoom = convoRoom;
      await _currentRoom!.getProfile().then((value) {
        if (value.hasAvatar()) {
          roomAvatar = value.getAvatar();
        }
        roomName = value.getDisplayName();
      });
      update(['room-profile']);
      isLoading.value = true;
      activeMembers = await _getActiveMembers();
      update(['active-members']);
      if (_currentRoom == null) {
        return; // user may close chat screen before long loading completed
      }
      _stream = await _currentRoom!.timeline();
      // i am fetching messages from remote
      if (_currentRoom == null) {
        return; // user may close chat screen before long loading completed
      }
      var msgs = await _stream!.paginateBackwards(10);
      for (RoomMessage message in msgs) {
        _loadMessage(message);
      }
      // load receipt status of room
      var receiptController = Get.find<ReceiptController>();
      var receipts = (await convoRoom.userReceipts()).toList();
      if (_currentRoom == null) {
        return; // user may close chat screen before long loading completed
      }
      receiptController.loadRoom(convoRoom.getRoomId(), receipts);
      isLoading.value = false;
    }
  }

  String? currentRoomId() {
    return _currentRoom?.getRoomId();
  }

  Future<List<Map<String, dynamic>>> _getActiveMembers() async {
    List<Member> members = (await _currentRoom!.activeMembers())
        .where((x) => x.userId() != client.userId().toString())
        .toList();
    List<Map<String, dynamic>> records = [];
    for (Member member in members) {
      UserProfile profile = await member.getProfile();
      Map<String, dynamic> record = {
        'display': profile.getDisplayName(),
        'link': member.userId(),
      };
      if (profile.hasAvatar()) {
        record['avatar'] = profile.getAvatar();
      }
      records.add(record);
    }
    return records;
  }

  Future<FfiBufferUint8>? getUserAvatar(String userId) {
    Future<FfiBufferUint8>? avatar;
    for (var e in activeMembers) {
      if (e['link'] == userId) {
        avatar = e['avatar'];
      } else {
        avatar = null;
      }
    }
    return avatar;
  }

  String? getUserName(String userId) {
    String? username;
    for (var e in activeMembers) {
      if (e['link'] == userId) {
        username = e['display'];
      } else {
        username = null;
      }
    }
    return username;
  }

  //preview message link
  void handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final idx = messages.indexWhere((element) => element.id == message.id);
    final updatedMessage =
        (messages[idx] as types.TextMessage).copyWith(previewData: previewData);

    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    var eventId = await _currentRoom!.sendFormattedMessage(markdownMessage);
    final textMessage = types.TextMessage(
      author: types.User(id: client.userId().toString()),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: eventId,
      text: htmlMessage,
      status: types.Status.sent,
      showStatus: true,
      metadata: {
        'messageLength': messageLength,
      },
    );
    messages.insert(0, textMessage);
    update(['Chat']);
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
      var eventId = await _currentRoom!.sendImageMessage(
        result.path,
        result.name,
        mimeType!,
        bytes.length,
        image.width,
        image.height,
      );

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
      messages.insert(0, message);
      update(['Chat']);
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

      // i am sending message
      final message = types.FileMessage(
        author: types.User(id: client.userId().toString()),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: randomString(),
        name: result.files.single.name,
        size: result.files.single.size,
        uri: result.files.single.path!,
      );
      Navigator.pop(context);
      messages.insert(0, message);
      update(['Chat']);
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
    final msgs = await _stream!.paginateBackwards(10);
    // i am fetching messages from remote
    for (RoomMessage message in msgs) {
      _loadMessage(message);
    }
    _page = _page + 1;
    update(['Chat']);
  }

  void _insertMessage(types.Message m) {
    var receiptController = Get.find<ReceiptController>();
    List<String> seenByList = receiptController.getSeenByList(
      _currentRoom!.getRoomId(),
      m.createdAt!,
    );
    var msg = (m.author.id == client.userId().toString())
        ? m.copyWith(
            showStatus: true,
            status: seenByList.length < activeMembers.length
                ? types.Status.delivered
                : types.Status.seen,
          )
        : m;
    for (var i = 0; i < messages.length; i++) {
      if (messages[i].createdAt! < m.createdAt!) {
        messages.insert(i, msg);
        return;
      }
    }
    messages.add(msg);
  }

  void _loadMessage(RoomMessage message) {
    String msgtype = message.msgtype();
    String sender = message.sender();
    var author = types.User(
      id: sender,
      firstName: simplifyUserId(sender),
    );
    int createdAt = message.originServerTs(); // in milliseconds
    String eventId = message.eventId();

    if (msgtype == 'm.audio') {
    } else if (msgtype == 'm.emote') {
    } else if (msgtype == 'm.file') {
      FileDescription? description = message.fileDescription();
      if (description != null) {
        types.FileMessage m = types.FileMessage(
          author: author,
          createdAt: createdAt,
          id: eventId,
          name: description.name(),
          size: description.size() ?? 0,
          uri: '',
        );
        _insertMessage(m);
      }
      if (isLoading.isFalse) {
        update(['Chat']);
      }
    } else if (msgtype == 'm.image') {
      ImageDescription? description = message.imageDescription();
      if (description != null) {
        types.ImageMessage m = types.ImageMessage(
          author: author,
          createdAt: createdAt,
          height: description.height()?.toDouble(),
          id: eventId,
          name: description.name(),
          size: description.size() ?? 0,
          uri: '',
          width: description.width()?.toDouble(),
        );
        _insertMessage(m);
        if (isLoading.isFalse) {
          update(['Chat']);
        }
        _currentRoom!.imageBinary(eventId).then((data) {
          int idx = messages.indexWhere((x) => x.id == eventId);
          if (idx != -1) {
            messages[idx] = messages[idx].copyWith(
              metadata: {
                'binary': data.asTypedList(),
              },
            );
            update(['Chat']);
          }
        });
      }
    } else if (msgtype == 'm.location') {
    } else if (msgtype == 'm.notice') {
    } else if (msgtype == 'm.server_notice') {
    } else if (msgtype == 'm.text') {
      types.TextMessage m = types.TextMessage(
        author: author,
        createdAt: createdAt,
        id: eventId,
        text: message.formattedBody() ?? message.body(),
        metadata: {
          'messageLength': message.body().length,
        },
      );
      _insertMessage(m);
      if (isLoading.isFalse) {
        update(['Chat']);
      }
    } else if (msgtype == 'm.video') {
    } else if (msgtype == 'm.key.verification.request') {}
  }

  void sendButtonUpdate() {
    isSendButtonVisible =
        mentionKey.currentState!.controller!.text.trim().isNotEmpty;
    update();
  }

  Future<bool> typingNotice(bool typing) async {
    if (_currentRoom == null) {
      return Future.value(false);
    }
    return await _currentRoom!.typingNotice(typing);
  }
}
