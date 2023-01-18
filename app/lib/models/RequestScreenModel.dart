import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';

class RequestScreenModel {
  RequestScreenModel({
    required this.client,
    required this.room,
  });

  Client client;
  Conversation room;

}