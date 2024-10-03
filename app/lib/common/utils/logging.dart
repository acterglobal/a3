import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final Map<(String, String), bool> logStateCache = {};

Future<void> initLogging() async {
  Logger.root.level = Level.INFO;
  final sdk = await ActerSdk.instance;
  Logger.root.onRecord.listen((record) {
    final loggerName = record.loggerName;
    final level = record.level;
    final time = record.time;
    final message = record.message;
    debugPrint('[$loggerName][${level.name}]: $time: $message');

    String levelName = switch (level) {
      Level.WARNING => 'warn',
      Level.SEVERE || Level.SHOUT => 'error',
      Level.INFO => 'info',
      Level.CONFIG => 'debug',
      _ => 'trace',
    };

    bool? curVal = logStateCache[(loggerName, levelName)];
    if (curVal == null) {
      curVal = sdk.api.wouldLog(loggerName, levelName);
      logStateCache[(loggerName, levelName)] = curVal;
    }

    if (curVal) {
      final error = record.error;
      final object = record.object;
      final stackTrace = record.stackTrace;
      sdk.api.writeLog(
        loggerName,
        levelName,
        '$message $error $object $stackTrace',
        null,
        null,
        null,
      );
    }
  });
}
