import 'package:acter/common/actions/open_link.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/main.dart';
import 'package:acter/config/env.g.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsOptInWidget extends ConsumerWidget {
  static const continueBtn = Key('analytics-continue-btn');

  const AnalyticsOptInWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
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
                _buildIcon(context),
                const SizedBox(height: 20),
                _buildTitleText(context, lang, textTheme),
                const SizedBox(height: 10),
                _buildDescriptionText(lang, textTheme),
                const SizedBox(height: 30),
                _buildMoreDetails(context, lang, textTheme, ref),
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

  Widget _buildIcon(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close),
      ),
    );
  }

  // widget for title text
  Widget _buildTitleText(BuildContext context, L10n lang, TextTheme textTheme) {
    return Text(
      lang.analyticsTitle,
      style: textTheme.headlineMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }

  // widget for description text
  Widget _buildDescriptionText(L10n lang, TextTheme textTheme) {
    return Text(
      lang.analyticsDescription,
      style: textTheme.bodyMedium,
      textAlign: TextAlign.center,
    );
  }

  // widget for "More Details" text
  Widget _buildMoreDetails(
    BuildContext context,
    L10n lang,
    TextTheme textTheme,
    WidgetRef ref,
  ) {
    final primaryColor = Theme.of(context).colorScheme.primary;
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
    final preferences = ref.watch(analyticsPreferencesProvider);

    final allowReportSending = preferences[canReportSentry] ?? isNightly;
    final matomoAnalyticsEnabled = preferences[matomoAnalytics] ?? isNightly;
    final basicTelemetryEnabled = preferences[basicTelemetry] ?? isNightly;
    final researchEnabled = preferences[research] ?? isNightly;

    final allEnabled =
        allowReportSending &&
        matomoAnalyticsEnabled &&
        basicTelemetryEnabled &&
        researchEnabled;

    return Column(
      children: [
        _buildToggleAllOption(lang.togglleAll, allEnabled, () async {
          final newValue = !allEnabled;
          final telemetryAnalyticsNotifier = ref.read(
            analyticsPreferencesProvider.notifier,
          );
          await telemetryAnalyticsNotifier.setPreference(
            canReportSentry,
            newValue,
            ref,
          );
          await telemetryAnalyticsNotifier.setPreference(
            matomoAnalytics,
            newValue,
            ref,
          );
          await telemetryAnalyticsNotifier.setPreference(
            basicTelemetry,
            newValue,
            ref,
          );
          await telemetryAnalyticsNotifier.setPreference(
            research,
            newValue,
            ref,
          );
        }, context),
        _buildAnalyticsCard(
          context,
          lang.sendCrashReportsTitle,
          lang.sendCrashReportsInfo,
          allowReportSending,
          (value) async {
            await ref
                .read(analyticsPreferencesProvider.notifier)
                .setPreference(canReportSentry, value, ref);
          },
        ),
        _buildAnalyticsCard(
          context,
          lang.basicTelemetry,
          lang.basicTelemetryInfo,
          basicTelemetryEnabled,
          (value) async {
            await ref
                .read(analyticsPreferencesProvider.notifier)
                .setPreference(basicTelemetry, value, ref);
          },
        ),
        _buildAnalyticsCard(
          context,
          lang.appAnalytics,
          lang.appAnalyticsInfo,
          matomoAnalyticsEnabled,
          (value) async {
            await ref
                .read(analyticsPreferencesProvider.notifier)
                .setPreference(matomoAnalytics, value, ref);
          },
        ),
        _buildAnalyticsCard(
          context,
          lang.research,
          lang.researchInfo,
          researchEnabled,
          (value) async {
            await ref
                .read(analyticsPreferencesProvider.notifier)
                .setPreference(research, value, ref);
          },
        ),
      ],
    );
  }

  // Reusable widget for switch toggle option without card
  Widget _buildToggleAllOption(
    String text,
    bool value,
    Future<void> Function() onToggle,
    BuildContext context,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(text),
        Transform.scale(
          scale: 0.6,
          child: Switch(value: value, onChanged: (_) => onToggle()),
        ),
      ],
    );
  }

  // widget for analytics card with separate preference
  Widget _buildAnalyticsCard(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    Future<void> Function(bool) onToggle,
  ) {
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
}
