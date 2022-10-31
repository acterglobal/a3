#include "include/effektio_flutter_sdk/effektio_flutter_sdk_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "effektio_flutter_sdk_plugin.h"

void EffektioFlutterSdkPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  effektio_flutter_sdk::EffektioFlutterSdkPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
