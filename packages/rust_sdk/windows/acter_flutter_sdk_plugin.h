#ifndef FLUTTER_PLUGIN_ACTER_FLUTTER_SDK_PLUGIN_H_
#define FLUTTER_PLUGIN_ACTER_FLUTTER_SDK_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace acter_flutter_sdk {

class ActerFlutterSdkPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  ActerFlutterSdkPlugin();

  virtual ~ActerFlutterSdkPlugin();

  // Disallow copy and assign.
  ActerFlutterSdkPlugin(const ActerFlutterSdkPlugin&) = delete;
  ActerFlutterSdkPlugin& operator=(const ActerFlutterSdkPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace acter_flutter_sdk

#endif  // FLUTTER_PLUGIN_ACTER_FLUTTER_SDK_PLUGIN_H_
