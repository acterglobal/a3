import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/main.dart';
import 'package:acter/common/utils/routes.dart';
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
    return Scaffold(
      body: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Text(
              L10n.of(context).analyticsTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              L10n.of(context).analyticsDescription1,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Text(
              L10n.of(context).analyticsDescription2,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            _buildCrashAnalytics(context, ref),
            const SizedBox(height: 40),
            _buildSkipActionButton(context),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildCrashAnalytics(BuildContext context, WidgetRef ref) {
    final allowReportSending =
        ref.watch(allowSentryReportingProvider).valueOrNull ?? isNightly;

    void toggle(bool? input) {
      setCanReportToSentry(input ?? (!allowReportSending));
      ref.invalidate(allowSentryReportingProvider);
    }

    return ListTile(
      onTap: () => toggle(null),
      title: Text(L10n.of(context).sendCrashReportsTitle),
      subtitle: Text(L10n.of(context).sendCrashReportsInfo),
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
