import 'dart:io';

import 'package:acter/config/env.g.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';

const userAgent = '${Env.rageshakeAppName}/${Env.rageshakeAppName}';
final defaultLogSetting = Platform.environment.containsKey(rustLogKey)
    ? Platform.environment[rustLogKey] as String
    : Env.defaultRustLog;

void configSetup() {
  // Pass the configuration to the SDK plugin
  ActerSdk.setup(
    sessionKey: Env.defaultActerSession,
    userAgent: userAgent,
    defaultLogSetting: defaultLogSetting,
    appleKeychainAppGroupName: Env.appleKeychainAppGroupName,
    defaultHomeServerName: Env.defaultHomeserverName,
    defaultHomeServerUrl: Env.defaultHomeserverUrl,
    defaultHttpProxy: Env.defaultHttpProxy,
  );
}
