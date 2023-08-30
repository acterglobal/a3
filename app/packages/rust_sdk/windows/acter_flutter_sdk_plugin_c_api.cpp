#include "include/acter_flutter_sdk/acter_flutter_sdk_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "acter_flutter_sdk_plugin.h"

void ActerFlutterSdkPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  acter_flutter_sdk::ActerFlutterSdkPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
