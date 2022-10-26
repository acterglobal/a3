import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_method_channel.dart';

void main() {
  MethodChannelEffektioFlutterSdk platform = MethodChannelEffektioFlutterSdk();
  const MethodChannel channel = MethodChannel('effektio_flutter_sdk');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
