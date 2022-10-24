import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'effektio_flutter_sdk_method_channel.dart';

abstract class EffektioFlutterSdkPlatform extends PlatformInterface {
  /// Constructs a EffektioFlutterSdkPlatform.
  EffektioFlutterSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static EffektioFlutterSdkPlatform _instance = MethodChannelEffektioFlutterSdk();

  /// The default instance of [EffektioFlutterSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelEffektioFlutterSdk].
  static EffektioFlutterSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [EffektioFlutterSdkPlatform] when
  /// they register themselves.
  static set instance(EffektioFlutterSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
