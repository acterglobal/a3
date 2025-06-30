import 'package:acter/features/onboarding/pages/redeem_invitations_page.dart';
import 'package:acter/features/onboarding/pages/save_username_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acter/features/onboarding/pages/onboarding_page.dart';
import 'package:acter/features/onboarding/providers/onboarding_provider.dart';
import 'package:acter/features/backups/providers/backup_state_providers.dart';
import 'package:acter/features/backups/providers/notifiers/backup_state_notifier.dart';
import 'package:acter/features/backups/types.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../../helpers/test_util.dart';

class MockRecoveryStateNotifier extends RecoveryStateNotifier {
  final RecoveryState _state;

  MockRecoveryStateNotifier(this._state);

  @override
  RecoveryState build() => _state;
}

void main() {
  Future<void> createWidgetUnderTest({
    bool isLogin = false,
    String? username = 'user',
    required WidgetTester tester,
  }) {
    return tester.pumpProviderWidget(
      child: MaterialApp(
        localizationsDelegates: [
          L10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              height: 800, // Provide enough height to prevent overflow
              child: OnboardingPage(isLoginOnboarding: isLogin, username: username),
            ),
          ),
        ),
      ),
      overrides: [
        onboardingPermissionsProvider.overrideWith(
          (ref) => Future.value(
            OnboardingPermissions(
              showNotificationPermission: false,
              showCalendarPermission: false,
            ),
          ),
        ),
        backupStateProvider.overrideWith(
          () => MockRecoveryStateNotifier(RecoveryState.disabled),
        ),
      ],
    );
  }

  testWidgets('Renders SaveUsernamePage when not login onboarding', (
    tester,
  ) async {
    await createWidgetUnderTest(tester: tester, username: 'user');
    await tester.pumpAndSettle(); // Wait for the provider to resolve

    expect(find.byType(SaveUsernamePage), findsOneWidget);
  });

  testWidgets('Navigates to next page on callNextPage', (tester) async {
    await createWidgetUnderTest(tester: tester, username: 'test_user');
    await tester.pumpAndSettle(); // Wait for the provider to resolve

    // SaveUsernamePage should exist
    expect(find.byType(SaveUsernamePage), findsOneWidget);

    // Tap next programmatically
    final savePage = tester.widget<SaveUsernamePage>(
      find.byType(SaveUsernamePage),
    );
    savePage.callNextPage?.call();

    // Let widget animate to next page
    await tester.pumpAndSettle();

    // Now we should be on RedeemInvitationsPage
    expect(find.byType(RedeemInvitationsPage), findsOneWidget);
  });

  testWidgets('Page indicator shows correct number of dots', (tester) async {
    await createWidgetUnderTest(tester: tester, username: 'test_user');
    await tester.pumpAndSettle(); // Wait for the provider to resolve

    // Count number of indicator dots
    final indicatorDots = find.byWidgetPredicate(
      (widget) => widget is Container && widget.decoration is BoxDecoration,
    );

    // 5 onboarding + permissions (may vary) + analytics
    expect(indicatorDots.evaluate().length, greaterThanOrEqualTo(8));
  });
}
