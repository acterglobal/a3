import Flutter
import UIKit

public class SwiftActerFlutterSdkPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "acter_flutter_sdk", binaryMessenger: registrar.messenger())
    let instance = SwiftActerFlutterSdkPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }

  public func dummyMethodToEnforceBundling() {
    // This will never be executed but is needed to ensure
    // the lib is linked properly
    __hello_world();
  }
}
