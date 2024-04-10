import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final Map<(String, String), bool> logStateCache = {};

Future<void> initLogging() async {
  Logger.root.level = Level.INFO;
  final sdk = await ActerSdk.instance;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
    String level = 'trace';
    if (record.level == Level.WARNING) {
      level = 'warn';
    } else if (record.level == Level.SEVERE || record.level == Level.SHOUT) {
      level = 'error';
    } else if (record.level == Level.INFO) {
      level = 'info';
    } else if (record.level == Level.CONFIG) {
      level = 'debug';
    }

    bool? curVal = logStateCache[(record.loggerName, level)];
    if (curVal == null) {
      curVal = sdk.api.wouldLog(record.loggerName, level);
      logStateCache[(record.loggerName, level)] = curVal;
    }

    if (curVal) {
      sdk.api.writeLog(
        record.loggerName,
        level,
        '${record.message} ${record.error} ${record.object} ${record.stackTrace}',
        null,
        null,
        null,
      );
    }
  });
}
