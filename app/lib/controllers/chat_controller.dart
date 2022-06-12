// ignore_for_file: always_declare_return_types

import 'package:effektio/common/widget/AppCommon.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show Conversation, TimelineStream, RoomMessage;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';

class ChatController extends GetxController {
  static ChatController get instance =>
      Get.put<ChatController>(ChatController());

  List<types.Message> messages = <types.Message>[];
  TimelineStream? _stream;
  bool isLoading = false;
  int _page = 0;
  late final Conversation room;
  late final types.User user;

  //get the timeline of room
  init(Conversation convoRoom, types.User convoUser) async {
    room = convoRoom;
    user = convoUser;
    isLoading = true;
    update(['Chat']);
    _stream = await room.timeline();
    var _messages = await _stream!.paginateBackwards(10);
    for (RoomMessage message in _messages) {
      types.TextMessage m = types.TextMessage(
        author: types.User(id: message.sender()),
        id: message.eventId(),
        text: message.body(),
      );
      messages.add(m);
    }
    if (messages.isNotEmpty) {
      if (messages.first.author.id == user.id) {
        bool isSeen = await room.readReceipt(messages.first.id);
        types.TextMessage lm = types.TextMessage(
          author: user,
          id: messages.first.id,
          text: _messages.first.body(),
          showStatus: true,
          status: isSeen ? types.Status.seen : types.Status.delivered,
        );
        messages.removeAt(0);
        messages.insert(0, lm);
      }
      isLoading = false;
      update(['Chat']);
    } else {
      isLoading = false;
      update(['Chat']);
    }
    newEvent();
    // isSeenMessage();
  }

  //waits for new event
  Future<void> newEvent() async {
    await _stream!.next();
    var newEvent = await room.latestMessage();
    final eventUser = types.User(
      id: newEvent.sender(),
    );
    final textMessage = types.TextMessage(
      id: newEvent.eventId(),
      author: eventUser,
      text: newEvent.body(),
    );
    messages.insert(0, textMessage);
    update(['Chat']);
  }

  //preview message link
  void handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final index = messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = messages[index].copyWith(previewData: previewData);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      messages[index] = updatedMessage;
      update(['Chat']);
    });
  }

  //push messages in conversation
  void handleSendPressed(types.PartialText message) async {
    await room.typingNotice(false);
    var eventId = await room.sendPlainMessage(message.text);
    final textMessage = types.TextMessage(
      author: user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: eventId,
      text: message.text,
      status: types.Status.sent,
      showStatus: true,
    );
    messages.insert(0, textMessage);
  }

  //image selection
  void handleImageSelection(BuildContext context) async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);

      final message = types.ImageMessage(
        author: user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        height: image.height.toDouble(),
        id: randomString(),
        name: result.name,
        size: bytes.length,
        uri: result.path,
        width: image.width.toDouble(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('The File that is uploaded isn\'t sent to the server.'),
        ),
      );
      Navigator.pop(context);
      messages.insert(0, message);
      update(['Chat']);
    }
  }

  //file selection
  void handleFileSelection(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final message = types.FileMessage(
        author: user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: randomString(),
        name: result.files.single.name,
        size: result.files.single.size,
        uri: result.files.single.path!,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('The File that is uploaded isn\'t sent to the server.'),
        ),
      );
      Navigator.pop(context);
      messages.insert(0, message);
      update(['Chat']);
    }
  }

  void handleMessageTap(BuildContext context, types.Message message) async {
    if (message is types.FileMessage) {
      await OpenFile.open(message.uri);
    }
  }

  //Pagination Control
  Future<void> handleEndReached() async {
    final _messages = await _stream!.paginateBackwards(10);
    final List<types.Message> nextMessages = <types.Message>[];
    for (RoomMessage message in _messages) {
      types.TextMessage m = types.TextMessage(
        author: types.User(id: message.sender()),
        id: message.eventId(),
        text: message.body(),
      );
      nextMessages.add(m);
    }
    messages = [...messages, ...nextMessages];
    _page = _page + 1;
    update(['Chat']);
  }
}
