import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

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

Future<TimelineStream> getTimeline(Room room) async {
  var timeline = await room.timeline();
  return timeline;
}

Future<List<types.Message>> getMessages(
  TimelineStream stream,
  int count,
) async {
  final List<types.Message> _messages = [];
  var messages = await stream.paginateBackwards(count);
  for (RoomMessage message in messages) {
    types.TextMessage m = types.TextMessage(
      id: message.eventId(),
      author: types.User(id: message.sender()),
      text: message.body(),
    );
    _messages.add(m);
  }
  return _messages;
}
