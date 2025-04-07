import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/main.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AnalyticsOptInPage extends ConsumerWidget {
  static const continueBtn = Key('analytics-continue-btn');

  const AnalyticsOptInPage({super.key});

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              _buildCloseButton(context),
              const SizedBox(height: 10),
              _buildTitleText(context, lang, textTheme),
              const SizedBox(height: 10),
              _buildDescriptionText(lang, textTheme),
              const SizedBox(height: 30),
              _buildMoreDetails(context, lang, textTheme),
              const SizedBox(height: 10),
              _buildCrashAnalytics(context, ref, textTheme),
              const SizedBox(height: 40),
              _buildActionButton(context),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  // widget for close button
  Widget _buildCloseButton(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
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
  Widget _buildMoreDetails(BuildContext context, L10n lang, TextTheme textTheme) {
    return Text(
      lang.analyticsMoreDetails,
      style: textTheme.bodyMedium?.copyWith(
        decoration: TextDecoration.underline,
        decorationColor: Theme.of(context).colorScheme.primary,
        decorationThickness: 2,
        color: Theme.of(context).colorScheme.primary,
      ),
      textAlign: TextAlign.center,
    );
  }

  // Refactored crash analytics section with toggle functionality
  Widget _buildCrashAnalytics(BuildContext context, WidgetRef ref, TextTheme textTheme) {
    final lang = L10n.of(context);
    final allowReportSending = ref.watch(allowSentryReportingProvider).valueOrNull ?? isNightly;
 
    void toggle(bool? input) {
      setCanReportToSentry(input ?? !allowReportSending);
      ref.invalidate(allowSentryReportingProvider);
    }

    return Column(
      children: [
        _buildSwitchOption(
          lang.togglleAll,
          allowReportSending,
          () => toggle(null),
          context,
        ),
        _buildCrashAnalyticsCard(
          lang.sendCrashReportsTitle,
          lang.sendCrashReportsInfo,
          allowReportSending,
          toggle,
          context,
          textTheme,
        ),
        _buildCrashAnalyticsCard(
          lang.basicTelemetry,
          lang.basicTelemetryInfo,
          allowReportSending,
          toggle,
          context,
          textTheme,
        ),
        _buildCrashAnalyticsCard(
          lang.appAnalytics,
          lang.appAnalyticsInfo,
          allowReportSending,
          toggle,
          context,
          textTheme,
        ),
        _buildCrashAnalyticsCard(
          lang.research,
          lang.researchInfo,
          allowReportSending,
          toggle,
          context,
          textTheme,
        ),
      ],
    );
  }

  // widget for switch toggle card
  Widget _buildCrashAnalyticsCard(
    String title,
    String subtitle,
    bool value,
    void Function(bool?) toggle,
    BuildContext context,
    TextTheme textTheme,
  ) {
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: ListTile(
        onTap: () => toggle(null),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        trailing: Transform.scale(
          scale: 0.6,
          child: Switch(
            value: value,
            onChanged: (value) => toggle(value),
          ),
        ),
      ),
    );
  }

  // Reusable widget for switch toggle option without card
  Widget _buildSwitchOption(
    String text,
    bool value,
    VoidCallback onToggle,
    BuildContext context,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(text),
        Transform.scale(
          scale: 0.6,
          child: Switch(
            value: value,
            onChanged: (value) => onToggle(),
          ),
        ),
      ],
    );
  }

  // Action button to proceed
  Widget _buildActionButton(BuildContext context) {
    return ActerPrimaryActionButton(
      key: AnalyticsOptInPage.continueBtn,
      onPressed: () => context.goNamed(Routes.main.name),
      child: Text(
        L10n.of(context).wizzardContinue,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
