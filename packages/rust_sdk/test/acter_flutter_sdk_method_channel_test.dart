import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_method_channel.dart';

void main() {
  MethodChannelActerFlutterSdk platform = MethodChannelActerFlutterSdk();
  const MethodChannel channel = MethodChannel('acter_flutter_sdk');

  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getPlatformVersion', (widgetTester) async {
    widgetTester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
    expect(await platform.getPlatformVersion(), '42');
  });
}
