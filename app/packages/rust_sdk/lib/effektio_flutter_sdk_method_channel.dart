import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'effektio_flutter_sdk_platform_interface.dart';

/// An implementation of [EffektioFlutterSdkPlatform] that uses method channels.
class MethodChannelEffektioFlutterSdk extends EffektioFlutterSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('effektio_flutter_sdk');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
