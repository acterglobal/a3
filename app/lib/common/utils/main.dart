import 'package:acter/common/utils/constants.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

const canReportSentry = 'allowToReportToSentry';

Future<bool> getCanReportToSentry() async {
  final prefs = await sharedPrefs();
  final value = prefs.getBool(canReportSentry);
  if (value == null) return isNightly; // on nightly, we are default on
  return value;
}

Future<bool> setCanReportToSentry(bool input) async {
  final prefs = await sharedPrefs();
  prefs.setBool(canReportSentry, input);
  return getCanReportToSentry();
}

Future<SentryEvent?> sentryBeforeSend(SentryEvent evt, Hint hint) async {
  if (!await getCanReportToSentry()) {
    return null;
  }
  return evt;
}
