import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/notifiers/client_pref_notifier.dart';
import 'package:acter/config/setup.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// Analytics preference keys
const String canReportSentryKey = 'analytics.sentry';
const String matomoAnalyticsKey = 'analytics.matomo';
const String basicTelemetryKey = 'analytics.telemetry';
const String researchKey = 'analytics.research';

// Analytics preference providers
final canReportSentryProvider = createAsyncPrefProvider<bool>(
  prefKey: canReportSentryKey,
  defaultValue: false,
);

final matomoAnalyticsProvider = createAsyncPrefProvider<bool>(
  prefKey: matomoAnalyticsKey,
  defaultValue: false,
);

final basicTelemetryProvider = createAsyncPrefProvider<bool>(
  prefKey: basicTelemetryKey,
  defaultValue: false,
);

final researchProvider = createAsyncPrefProvider<bool>(
  prefKey: researchKey,
  defaultValue: false,
);

Future<SentryEvent?> sentryBeforeSend(SentryEvent evt, Hint hint) async {
  final canReport = await mainProviderContainer.read(canReportSentryProvider.future);
  if (!canReport) {
    return null;
  }
  return evt;
}

/// Handles Matomo-specific analytics settings
Future<void> setMatomoAnalytics(bool value, WidgetRef ref) async {
  // Update Matomo tracking state
  MatomoTracker.instance.setOptOut(optOut: value);

  // Set visitor ID if enabled
  final userId = ref.read(myUserIdStrProvider);
  setMatomoUserId(userId);
}

/// Sets the visitor ID for Matomo tracking
void setMatomoUserId(String userId) {
  MatomoTracker.instance.setVisitorUserId(userId);
}

// Helper function to update analytics preferences
Future<void> updateAnalyticsPreference(
  String key,
  bool value,
  WidgetRef ref,
) async {
  await switch (key) {
    matomoAnalyticsKey => () async {
      await ref.read(matomoAnalyticsProvider.notifier).set(value);
      await setMatomoAnalytics(value, ref);
    }(),
    canReportSentryKey => ref.read(canReportSentryProvider.notifier).set(value),
    basicTelemetryKey => ref.read(basicTelemetryProvider.notifier).set(value),
    researchKey => ref.read(researchProvider.notifier).set(value),
    _ => throw ArgumentError('Unknown analytics preference key: $key'),
  };
}
