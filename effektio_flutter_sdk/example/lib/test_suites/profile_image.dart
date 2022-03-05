import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:effektio_flutter_sdk_example/constants.dart';
import 'package:effektio_flutter_sdk_example/test_suites/interface.dart';
import 'package:flutter/cupertino.dart';

class AvatarTest extends TestSuite {
  @override
  Stream<String> executeTest() async* {
    yield 'Initializing SDK';
    final sdk = await EffektioSdk.instance;
    yield 'Logging in';
    final client = await sdk.login(username, password);
    yield 'Fetching avatar';
    final avatar = await client.avatar().then((buffer) => buffer.toUint8List());
    yield 'Verifying response';
    try {
      await PaintingBinding.instance!.instantiateImageCodec(avatar);
      yield 'done';
    } catch (_) {
      yield 'ERROR: client.avatar() returned invalid data';
    }
  }

  @override
  Future<void> setup() async {}

  @override
  Future<void> teardown() async {}
}
