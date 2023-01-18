import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';

class ChatProfileModel {
  ChatProfileModel({
    required this.client,
    required this.room,
    required this.isGroup,
    required this.isAdmin,
    this.roomName,
    this.roomAvatar,
  });

  Client client;
  Conversation room;
  String? roomName;
  Future<FfiBufferUint8>? roomAvatar;
  bool isGroup;
  bool isAdmin;

}