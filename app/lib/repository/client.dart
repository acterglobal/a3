import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';

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
