import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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

    String levelName = 'trace';
    if (level == Level.WARNING) {
      levelName = 'warn';
    } else if (level == Level.SEVERE || level == Level.SHOUT) {
      levelName = 'error';
      Sentry.captureMessage(record.message, level: SentryLevel.error);
      final exception = record.object;
      if (exception != null) {
        Sentry.captureException(exception, stackTrace: record.stackTrace);
      }
    } else if (level == Level.INFO) {
      levelName = 'info';
    } else if (level == Level.CONFIG) {
      levelName = 'debug';
    }

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
