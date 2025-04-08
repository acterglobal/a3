import 'package:acter/common/utils/constants.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:matomo_tracker/matomo_tracker.dart';

const canReportSentry = 'allowToReportToSentry';
const matomoAnalytics = 'appAnalytics';

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

Future<bool> getMatomoAnalyticsEnabled() async {
  final prefs = await sharedPrefs();
  final value = prefs.getBool(matomoAnalytics);
  return value ?? false; // Default to off for privacy
}

Future<bool> setMatomoAnalyticsEnabled(bool input) async {
  final prefs = await sharedPrefs();
  await prefs.setBool(matomoAnalytics, input);

  // Update the Matomo opt-out setting(when we add the siteId and url)
  // MatomoTracker.instance.setOptOut(optOut: !input);

  return getMatomoAnalyticsEnabled();
}
