#ifndef FLUTTER_PLUGIN_EFFEKTIO_FLUTTER_SDK_PLUGIN_H_
#define FLUTTER_PLUGIN_EFFEKTIO_FLUTTER_SDK_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace effektio_flutter_sdk {

class EffektioFlutterSdkPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  EffektioFlutterSdkPlugin();

  virtual ~EffektioFlutterSdkPlugin();

  // Disallow copy and assign.
  EffektioFlutterSdkPlugin(const EffektioFlutterSdkPlugin&) = delete;
  EffektioFlutterSdkPlugin& operator=(const EffektioFlutterSdkPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace effektio_flutter_sdk

#endif  // FLUTTER_PLUGIN_EFFEKTIO_FLUTTER_SDK_PLUGIN_H_
