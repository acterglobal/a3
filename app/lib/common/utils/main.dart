import 'package:acter/common/utils/constants.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

const canReportSentry = 'allowToReportToSentry';    
const matomoAnalytics = 'appAnalytics';
const basicTelemetry = 'basicTelemetry';
const research = 'research';

Future<bool> getAnalyticsPreference(String key) async {
  final prefs = await sharedPrefs();
  final value = prefs.getBool(key);
  return value ?? isNightly; // Default to on for nightly builds
}

Future<void> setAnalyticsPreference(String key, bool value) async {
  final prefs = await sharedPrefs();
  await prefs.setBool(key, value);
  
  if (key == matomoAnalytics) {
    // Update the Matomo opt-out setting(when we add the siteId and url)
    // MatomoTracker.instance.setOptOut(optOut: !value);
  }
}

Future<SentryEvent?> sentryBeforeSend(SentryEvent evt, Hint hint) async {
  if (!await getAnalyticsPreference(canReportSentry)) {
    return null;
  }
  return evt;
}
