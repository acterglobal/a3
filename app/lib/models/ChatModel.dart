import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';

class ChatModel {
  ChatModel({
    required this.client,
    required this.room,
    this.roomName,
    this.roomAvatar,
  });

  Client client;
  Conversation room;
  Future<FfiBufferUint8>? roomAvatar;
  String? roomName;

}