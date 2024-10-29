import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/main.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AnalyticsOptInPage extends ConsumerWidget {
  static const skipBtn = Key('analytics-skip-btn');

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
              Text(
                lang.analyticsTitle,
                style: textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                lang.analyticsDescription1,
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Text(
                lang.analyticsDescription2,
                style: textTheme.bodyMedium,
              ),
              _buildCrashAnalytics(context, ref),
              const SizedBox(height: 40),
              _buildSkipActionButton(context),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCrashAnalytics(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final allowReportSending =
        ref.watch(allowSentryReportingProvider).valueOrNull ?? isNightly;

    void toggle(bool? input) {
      setCanReportToSentry(input ?? !allowReportSending);
      ref.invalidate(allowSentryReportingProvider);
    }

    return ListTile(
      onTap: () => toggle(null),
      title: Text(lang.sendCrashReportsTitle),
      subtitle: Text(lang.sendCrashReportsInfo),
      leading: Switch(
        value: allowReportSending,
        onChanged: (value) => toggle(value),
      ),
    );
  }

  Widget _buildSkipActionButton(BuildContext context) {
    return ActerPrimaryActionButton(
      key: AnalyticsOptInPage.skipBtn,
      onPressed: () => context.goNamed(Routes.main.name),
      child: Text(
        L10n.of(context).done,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
