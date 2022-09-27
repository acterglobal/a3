// ignore_for_file: always_declare_return_types

import 'dart:async';
import 'dart:io';

import 'package:effektio/controllers/receipt_controller.dart';
import 'package:effektio/screens/HomeScreens/chat/ImageSelectionScreen.dart';
import 'package:effektio/widgets/AppCommon.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show
        Conversation,
        FileDescription,
        ImageDescription,
        Member,
        RoomMessage,
        TimelineStream;
import 'package:file_picker/file_picker.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatRoomController extends GetxController {
  List<types.Message> messages = [];
  TimelineStream? _stream;
  RxBool isLoading = false.obs;
  int _page = 0;
  late final Conversation room;
  late final types.User user;
  final bool _isDesktop = !(Platform.isAndroid || Platform.isIOS);
  RxBool isEmojiVisible = false.obs;
  RxBool isattachmentVisible = false.obs;
  FocusNode focusNode = FocusNode();
  TextEditingController textEditingController = TextEditingController();
  bool isSendButtonVisible = false;
  final List<XFile> _imageFileList = [];
  final ReceiptController _receiptController = Get.find<ReceiptController>();
  late List<Member> activeMembers;

  //get the timeline of room
  Future<void> init(Conversation convoRoom, types.User convoUser) async {
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        isEmojiVisible.value = false;
        isattachmentVisible.value = false;
      }
    });
    room = convoRoom;
    user = convoUser;
    isLoading.value = true;
    activeMembers = (await room.activeMembers()).toList();
    _stream = await room.timeline();
    // i am fetching messages from remote
    var msgs = await _stream!.paginateBackwards(10);
    for (RoomMessage message in msgs) {
      loadMessage(message);
    }
    isLoading.value = false;
  }

  //preview message link
  void handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final index = messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = (messages[index] as types.TextMessage)
        .copyWith(previewData: previewData);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      messages[index] = updatedMessage;
      update(['Chat']);
    });
  }

  //push messages in conversation
  Future<void> handleSendPressed(String message) async {
    // image or video is sent automatically
    // user will click "send" button explicitly for text only
    await room.typingNotice(false);
    var eventId = await room.sendPlainMessage(message);
    final textMessage = types.TextMessage(
      author: user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: eventId,
      text: message,
      status: types.Status.sent,
      showStatus: true,
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
      var eventId = await room.sendImageMessage(
        result.path,
        result.name,
        mimeType!,
        bytes.length,
        image.width,
        image.height,
      );

      final message = types.ImageMessage(
        author: user,
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
      var eventId = await room.sendImageMessage(
        result.path,
        result.name,
        mimeType!,
        bytes.length,
        image.width,
        image.height,
      );

      // i am sending message
      final message = types.ImageMessage(
        author: user,
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
      await room.sendFileMessage(
        result.files.single.path!,
        result.files.single.name,
        mimeType!,
        result.files.single.size,
      );

      // i am sending message
      final message = types.FileMessage(
        author: user,
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
      String filePath = await room.filePath(message.id);
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
          await room.saveFile(message.id, dirPath);
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
      loadMessage(message);
    }
    _page = _page + 1;
    update(['Chat']);
  }

  void _insertMessage(types.Message m) {
    List<String> seenByList = _receiptController.getSeenByList(
      room.getRoomId(),
      m.createdAt!,
    );
    var msg = (m.author.id == user.id)
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

  void loadMessage(RoomMessage message) {
    String msgtype = message.msgtype();
    String sender = message.sender();
    var author = types.User(id: sender, firstName: getNameFromId(sender));
    int createdAt = message.originServerTs() * 1000;
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
        room.imageBinary(eventId).then((data) async {
          int idx = _findMessage(eventId);
          if (idx != -1) {
            messages[idx] = messages[idx].copyWith(
              metadata: {
                'binary': data.asTypedList(),
              },
            );
          }
          update(['Chat']);
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
        text: message.body(),
      );
      _insertMessage(m);
      if (isLoading.isFalse) {
        update(['Chat']);
      }
    } else if (msgtype == 'm.video') {
    } else if (msgtype == 'm.key.verification.request') {}
  }

  int _findMessage(String eventId) {
    for (var i = 0; i < messages.length; i++) {
      if (messages[i].id == eventId) {
        return i;
      }
    }
    return -1;
  }

  void sendButtonUpdate() {
    isSendButtonVisible = textEditingController.text.trim().isNotEmpty;
    update();
  }

  @override
  void onClose() {
    super.onClose();
    textEditingController.dispose();
    focusNode.removeListener(() {});
  }
}
