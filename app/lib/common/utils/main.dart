import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const canReportSentry = 'allowToReportToSentry';
const matomoAnalytics = 'appAnalytics';
const basicTelemetry = 'basicTelemetry';
const research = 'research';

/// Sets the visitor ID for Matomo tracking
void setMatomoUserId(String userId) {
  MatomoTracker.instance.setVisitorUserId(userId);
}

Future<bool> getAnalyticsPreference(String key) async {
  final prefs = await sharedPrefs();
  final value = prefs.getBool(key);
  return value ?? isNightly; // Default to on for nightly builds
}

/// Sets an analytics preference and returns the new value
Future<bool> setAnalyticsPreference(String key, bool value) async {
  final prefs = await sharedPrefs();
  await prefs.setBool(key, value);
  return value;
}

/// Handles Matomo-specific analytics settings
Future<void> setMatomoAnalytics(bool value, WidgetRef ref) async {
  // Update Matomo tracking state
  MatomoTracker.instance.setOptOut(optOut: value);

  // Set visitor ID if enabled
  final userId = ref.read(myUserIdStrProvider);
   setMatomoUserId(userId);
}

Future<SentryEvent?> sentryBeforeSend(SentryEvent evt, Hint hint) async {
  if (!await getAnalyticsPreference(canReportSentry)) {
    return null;
  }
  return evt;
}
