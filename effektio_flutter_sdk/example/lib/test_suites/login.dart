import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:effektio_flutter_sdk_example/constants.dart';
import 'package:effektio_flutter_sdk_example/test_suites/interface.dart';

class LoginTest extends TestSuite {
  @override
  Stream<String> executeTest() async* {
    yield "Initializing SDK";
    final sdk = await EffektioSdk.instance;
    yield "Logging in";
    final client = await sdk.login(username, password);
    yield "Client name: ${await client.displayName()}";
    yield "done";
  }

  @override
  Future<void> setup() async {}

  @override
  Future<void> teardown() async {}
}
