import 'dart:io';

import 'package:acter/config/env.g.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const userAgent = '${Env.rageshakeAppName}/${Env.rageshakeAppName}';
final defaultLogSetting = Platform.environment.containsKey(rustLogKey)
    ? Platform.environment[rustLogKey] as String
    : Env.defaultRustLog;

final mainProviderContainer = ProviderContainer();

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
