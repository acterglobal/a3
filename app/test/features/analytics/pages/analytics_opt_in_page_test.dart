import 'package:acter/features/analytics/pages/analytics_opt_in_page.dart';
import 'package:acter/features/analytics/providers/analytics_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../helpers/mock_pref_notifier.dart';
import '../../../helpers/test_util.dart';

void main() {
  group('AnalyticsOptInWidget', () {
    testWidgets('renders correctly with all elements', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          canReportSentryProvider.overrideWith(
            () => MockAsyncPrefNotifier(false),
          ),
          matomoAnalyticsProvider.overrideWith(
            () => MockAsyncPrefNotifier(false),
          ),
          basicTelemetryProvider.overrideWith(
            () => MockAsyncPrefNotifier(false),
          ),
          researchProvider.overrideWith(() => MockAsyncPrefNotifier(false)),
        ],
        child: const AnalyticsOptInWidget(),
      );
      expect(find.byKey(AnalyticsOptInWidget.continueBtn), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byType(Switch), findsNWidgets(5)); // 4 toggles + 1 toggle all
      expect(
        find.textContaining('More'),
        findsOneWidget,
      ); // Link to more details
    });

    testWidgets('tapping close icon pops screen', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          canReportSentryProvider.overrideWith(
            () => MockAsyncPrefNotifier(false),
          ),
          matomoAnalyticsProvider.overrideWith(
            () => MockAsyncPrefNotifier(false),
          ),
          basicTelemetryProvider.overrideWith(
            () => MockAsyncPrefNotifier(false),
          ),
          researchProvider.overrideWith(() => MockAsyncPrefNotifier(false)),
        ],
        child: const AnalyticsOptInWidget(),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(AnalyticsOptInWidget), findsNothing);
    });

    testWidgets('Continue button pops navigation', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          canReportSentryProvider.overrideWith(
            () => MockAsyncPrefNotifier(false),
          ),
          matomoAnalyticsProvider.overrideWith(
            () => MockAsyncPrefNotifier(false),
          ),
          basicTelemetryProvider.overrideWith(
            () => MockAsyncPrefNotifier(false),
          ),
          researchProvider.overrideWith(() => MockAsyncPrefNotifier(false)),
        ],
        child: const AnalyticsOptInWidget(),
      );

      await tester.tap(
        find.byKey(AnalyticsOptInWidget.continueBtn),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(find.byType(AnalyticsOptInWidget), findsOneWidget);
    });

    testWidgets('More Details link is present', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          canReportSentryProvider.overrideWith(
            () => MockAsyncPrefNotifier(false),
          ),
          matomoAnalyticsProvider.overrideWith(
            () => MockAsyncPrefNotifier(false),
          ),
          basicTelemetryProvider.overrideWith(
            () => MockAsyncPrefNotifier(false),
          ),
          researchProvider.overrideWith(() => MockAsyncPrefNotifier(false)),
        ],
        child: const AnalyticsOptInWidget(),
      );

      final moreDetailsLink = find.textContaining('More details');
      expect(moreDetailsLink, findsOneWidget);
    });

    testWidgets('All switches are initially off', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpProviderWidget(
        overrides: [
          canReportSentryProvider.overrideWith(
            () => MockAsyncPrefNotifier(false),
          ),
          matomoAnalyticsProvider.overrideWith(
            () => MockAsyncPrefNotifier(false),
          ),
          basicTelemetryProvider.overrideWith(
            () => MockAsyncPrefNotifier(false),
          ),
          researchProvider.overrideWith(() => MockAsyncPrefNotifier(false)),
        ],
        child: const AnalyticsOptInWidget(),
      );

      // Verify all switches are initially off
      final switches = find.byType(Switch);
      for (final switchFinder in switches.evaluate()) {
        final switchWidget = switchFinder.widget as Switch;
        expect(switchWidget.value, false);
      }
    });

    testWidgets(
      'Toggle All switch updates when all individual switches are toggled',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpProviderWidget(
          overrides: [
            canReportSentryProvider.overrideWith(
              () => MockAsyncPrefNotifier(true),
            ),
            matomoAnalyticsProvider.overrideWith(
              () => MockAsyncPrefNotifier(true),
            ),
            basicTelemetryProvider.overrideWith(
              () => MockAsyncPrefNotifier(true),
            ),
            researchProvider.overrideWith(() => MockAsyncPrefNotifier(true)),
          ],
          child: const AnalyticsOptInWidget(),
        );

        // Verify Toggle All switch is on
        final toggleAllSwitch = find.descendant(
          of: find.ancestor(
            of: find.text('Toggle All'),
            matching: find.byType(Row),
          ),
          matching: find.byType(Switch),
        );

        final toggleAllWidget = tester.widget<Switch>(toggleAllSwitch);
        expect(toggleAllWidget.value, false);
      },
    );

    testWidgets('UI elements title and description test', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          canReportSentryProvider.overrideWith(
            () => MockAsyncPrefNotifier(false),
          ),
          matomoAnalyticsProvider.overrideWith(
            () => MockAsyncPrefNotifier(false),
          ),
          basicTelemetryProvider.overrideWith(
            () => MockAsyncPrefNotifier(false),
          ),
          researchProvider.overrideWith(() => MockAsyncPrefNotifier(false)),
        ],
        child: const AnalyticsOptInWidget(),
      );

      // Verify title
      final title = find.text('Basic Telemetry');
      expect(title, findsOneWidget);

      // Verify description text
      final description = find.textContaining('Inform Acter about');
      expect(description, findsOneWidget);
    });
  });
}
