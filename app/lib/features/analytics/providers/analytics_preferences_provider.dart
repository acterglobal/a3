import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/notifiers/client_pref_notifier.dart';
import 'package:acter/config/setup.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matomo_tracker/matomo_tracker.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Enum representing different analytics preference keys
enum AnalyticsPreferenceKey {
  crashReporting,
  basicTelemetry,
  appAnalytics,
  research,
}

// Analytics preference providers
final canReportSentryProvider = createAsyncPrefProvider<bool>(
  prefKey: AnalyticsPreferenceKey.crashReporting.name,
  defaultValue: false,
);

final matomoAnalyticsProvider = createAsyncPrefProvider<bool>(
  prefKey: AnalyticsPreferenceKey.appAnalytics.name,
  defaultValue: false,
);

final basicTelemetryProvider = createAsyncPrefProvider<bool>(
  prefKey: AnalyticsPreferenceKey.basicTelemetry.name,
  defaultValue: false,
);

final researchProvider = createAsyncPrefProvider<bool>(
  prefKey: AnalyticsPreferenceKey.research.name,
  defaultValue: false,
);

Future<SentryEvent?> sentryBeforeSend(ProviderContainer container, SentryEvent evt, Hint hint) async {
  final canReport = await container.read(
    canReportSentryProvider.future,
  );
  if (!canReport) {
    return null;
  }
  return evt;
}

/// Handles Matomo-specific analytics settings
Future<void> setMatomoAnalytics(bool value, WidgetRef ref) async {
  // Update Matomo tracking state
  MatomoTracker.instance.setOptOut(optOut: !value);

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
  AnalyticsPreferenceKey key,
  bool value,
  WidgetRef ref,
) async {
  await switch (key) {
    AnalyticsPreferenceKey.appAnalytics => () async {
      await ref.read(matomoAnalyticsProvider.notifier).set(value);
      await setMatomoAnalytics(value, ref);
    }(),
    AnalyticsPreferenceKey.crashReporting =>
        ref.read(canReportSentryProvider.notifier).set(value),
    AnalyticsPreferenceKey.basicTelemetry =>
        ref.read(basicTelemetryProvider.notifier).set(value),
    AnalyticsPreferenceKey.research =>
        ref.read(researchProvider.notifier).set(value),
  };
}
