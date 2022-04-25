import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_types/flutter_chat_types.dart';

Future<Client> makeClient() async {
  final sdk = await EffektioSdk.instance;
  Client client = await sdk.currentClient;
  return client;
}

Future<Client> login(String username, String password) async {
  final sdk = await EffektioSdk.instance;
  Client client = await sdk.login(username, password);
  return client;
}

Future<String> getUser(Future<Client> client) async {
  Client _client = await client;
  final String userId = await _client.userId();
  return userId;
}

Future<List<types.Message>> getMessages(
  TimelineStream stream,
  int count,
  Conversation room,
) async {
  List<types.Message> _messages = [];
  bool isSeen = false;
  var messages = await stream.paginateBackwards(count);
  for (RoomMessage message in messages) {
    await room.readReceipt(message.eventId()).then(
          (value) => {
            isSeen = value,
          },
        );
    types.TextMessage m = types.TextMessage(
      id: message.eventId(),
      showStatus: true,
      author: types.User(id: message.sender()),
      text: message.body(),
      status: isSeen ? Status.seen : Status.delivered,
    );
    _messages.add(m);
    isSeen = !isSeen;
  }
  return _messages;
}

Future<String> sendMessage(Conversation convo, String message) async {
  var res = await convo.sendPlainMessage(message);
  return res;
}
