import 'package:acter/common/actions/open_link.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/config/env.g.dart';
import 'package:acter/features/analytics/providers/analytics_preferences_provider.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsOptInWidget extends ConsumerWidget {
  static const continueBtn = Key('analytics-continue-btn');

  const AnalyticsOptInWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    // ensure we are triggering a sync and do not delay this process
    // ignore: unused_local_variable, no_leading_underscores_for_local_identifiers
    final _syncState = ref.read(syncStateProvider);
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCloseIconButton(context),
                const SizedBox(height: 20),
                _buildTitleText(context, lang),
                const SizedBox(height: 10),
                _buildDescriptionText(context, lang),
                const SizedBox(height: 30),
                _buildMoreDetails(context, lang, ref),
                const SizedBox(height: 10),
                _buildTelemetryAnalytics(context, ref),
                const SizedBox(height: 30),
                _buildActionButton(context, lang),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCloseIconButton(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close),
      ),
    );
  }

  // widget for title text
  Widget _buildTitleText(BuildContext context, L10n lang) {
    return Text(
      lang.analyticsTitle,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }

  // widget for description text
  Widget _buildDescriptionText(BuildContext context, L10n lang) {
    return Text(
      lang.analyticsDescription,
      style: Theme.of(context).textTheme.bodyMedium,
      textAlign: TextAlign.center,
    );
  }

  // widget for "More Details" text
  Widget _buildMoreDetails(BuildContext context, L10n lang, WidgetRef ref) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap:
          () => openLink(
            ref: ref,
            target: Env.analyticsMoreDetailsUrl,
            lang: L10n.of(context),
          ),
      child: Text(
        lang.analyticsMoreDetails,
        style: textTheme.bodyMedium?.copyWith(
          decoration: TextDecoration.underline,
          decorationColor: primaryColor,
          decorationThickness: 2,
          color: primaryColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Refactored crash analytics section with toggle functionality
  Widget _buildTelemetryAnalytics(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);

    // Watch all analytics preferences
    final allowReportSendingAsync = ref.watch(canReportSentryProvider);
    final matomoAnalyticsAsync = ref.watch(matomoAnalyticsProvider);
    final basicTelemetryAsync = ref.watch(basicTelemetryProvider);
    final researchAsync = ref.watch(researchProvider);

    // Get the values or default to isNightly
    final allowReportSending = allowReportSendingAsync.value ?? isNightly;
    final matomoAnalyticsEnabled = matomoAnalyticsAsync.value ?? isNightly;
    final basicTelemetryEnabled = basicTelemetryAsync.value ?? isNightly;
    final researchEnabled = researchAsync.value ?? isNightly;

    final allEnabled =
        allowReportSending &&
        matomoAnalyticsEnabled &&
        basicTelemetryEnabled &&
        researchEnabled;

    return Column(
      children: [
        _buildToggleAllOption(
          context: context,
          text: lang.togglleAll,
          value: allEnabled,
          onToggle: (value) async {
            await _updateAllAnalyticsPreferences(ref, value);
          },
        ),
        _buildAnalyticsCard(
          context: context,
          title: lang.sendCrashReportsTitle,
          subtitle: lang.sendCrashReportsInfo,
          value: allowReportSending,
          onToggle: (value) async {
            await updateAnalyticsPreference(
              AnalyticsPreferenceKey.crashReporting,
              value,
              ref,
            );
          },
        ),
        _buildAnalyticsCard(
          context: context,
          title: lang.basicTelemetry,
          subtitle: lang.basicTelemetryInfo,
          value: basicTelemetryEnabled,
          onToggle: (value) async {
            await updateAnalyticsPreference(
              AnalyticsPreferenceKey.basicTelemetry,
              value,
              ref,
            );
          },
        ),
        _buildAnalyticsCard(
          context: context,
          title: lang.appAnalytics,
          subtitle: lang.appAnalyticsInfo,
          value: matomoAnalyticsEnabled,
          onToggle: (value) async {
            await updateAnalyticsPreference(
              AnalyticsPreferenceKey.appAnalytics,
              value,
              ref,
            );
          },
        ),
        _buildAnalyticsCard(
          context: context,
          title: lang.research,
          subtitle: lang.researchInfo,
          value: researchEnabled,
          onToggle: (value) async {
            await updateAnalyticsPreference(
              AnalyticsPreferenceKey.research,
              value,
              ref,
            );
          },
        ),
      ],
    );
  }

  // widget for switch toggle option without card
  Widget _buildToggleAllOption({
    required BuildContext context,
    required String text,
    required bool value,
    required Future<void> Function(bool) onToggle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(text),
        Transform.scale(
          scale: 0.6,
          child: Switch(value: value, onChanged: onToggle),
        ),
      ],
    );
  }

  // widget for analytics card with separate preference
  Widget _buildAnalyticsCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required Future<void> Function(bool) onToggle,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: ListTile(
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        trailing: Transform.scale(
          scale: 0.6,
          child: Switch(value: value, onChanged: onToggle),
        ),
      ),
    );
  }

  // Action button to proceed
  Widget _buildActionButton(BuildContext context, L10n lang) {
    return ActerPrimaryActionButton(
      key: AnalyticsOptInWidget.continueBtn,
      onPressed: () {
        if (context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Text(
        lang.wizzardContinue,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Future<void> _updateAllAnalyticsPreferences(
    WidgetRef ref,
    bool newValue,
  ) async {
    await updateAnalyticsPreference(AnalyticsPreferenceKey.crashReporting, newValue, ref);
    await updateAnalyticsPreference(AnalyticsPreferenceKey.basicTelemetry, newValue, ref);
    await updateAnalyticsPreference(AnalyticsPreferenceKey.appAnalytics, newValue, ref);
    await updateAnalyticsPreference(AnalyticsPreferenceKey.research, newValue, ref);
  }
}
