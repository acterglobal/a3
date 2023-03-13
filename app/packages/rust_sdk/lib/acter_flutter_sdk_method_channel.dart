import 'package:acter_flutter_sdk/acter_flutter_sdk_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

/// An implementation of [ActerFlutterSdkPlatform] that uses method channels.
class MethodChannelActerFlutterSdk extends ActerFlutterSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('acter_flutter_sdk');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
