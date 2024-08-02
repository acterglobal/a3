import 'package:flutter_test/flutter_test.dart';
// import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_platform_interface.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockActerFlutterSdkPlatform
    with MockPlatformInterfaceMixin
    implements ActerFlutterSdkPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ActerFlutterSdkPlatform initialPlatform =
      ActerFlutterSdkPlatform.instance;

  test('$MethodChannelActerFlutterSdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelActerFlutterSdk>());
  });
}
