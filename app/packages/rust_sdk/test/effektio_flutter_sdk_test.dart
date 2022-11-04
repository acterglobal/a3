import 'package:flutter_test/flutter_test.dart';
// import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_platform_interface.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockEffektioFlutterSdkPlatform
    with MockPlatformInterfaceMixin
    implements EffektioFlutterSdkPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final EffektioFlutterSdkPlatform initialPlatform =
      EffektioFlutterSdkPlatform.instance;

  test('$MethodChannelEffektioFlutterSdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelEffektioFlutterSdk>());
  });
}
