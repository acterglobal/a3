import 'package:acter_flutter_sdk/acter_flutter_sdk_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class ActerFlutterSdkPlatform extends PlatformInterface {
  /// Constructs a ActerFlutterSdkPlatform.
  ActerFlutterSdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static ActerFlutterSdkPlatform _instance = MethodChannelActerFlutterSdk();

  /// The default instance of [ActerFlutterSdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelActerFlutterSdk].
  static ActerFlutterSdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ActerFlutterSdkPlatform] when
  /// they register themselves.
  static set instance(ActerFlutterSdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
