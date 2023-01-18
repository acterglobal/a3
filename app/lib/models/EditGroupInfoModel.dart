import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';

class EditGroupInfoModel {
  EditGroupInfoModel({
    required this.name,
    required this.description,
    required this.room,
  });

  Conversation room;
  String name;
  String description;

}