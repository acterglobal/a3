import 'package:acter/features/onboarding/pages/redeem_invitations_page.dart';
import 'package:acter/features/onboarding/pages/save_username_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acter/features/onboarding/pages/onboarding_page.dart';

import '../../../helpers/test_util.dart';

void main() {
  Future<void> createWidgetUnderTest({
    bool isLogin = false,
    String? username,
    required WidgetTester tester,
  }) {
    return tester.pumpProviderWidget(
      child: OnboardingPage(isLoginOnboarding: isLogin, username: username),
    );
  }

  testWidgets('Renders SaveUsernamePage when not login onboarding', (
    tester,
  ) async {
    await createWidgetUnderTest(tester: tester, username: 'test_user');

    expect(find.byType(SaveUsernamePage), findsOneWidget);
  });

  testWidgets('Skips SaveUsernamePage when isLoginOnboarding is true', (
    tester,
  ) async {
    await createWidgetUnderTest(tester: tester, isLogin: true);

    expect(find.byType(SaveUsernamePage), findsNothing);
  });

  testWidgets('Navigates to next page on callNextPage', (tester) async {
    await createWidgetUnderTest(tester: tester, username: 'test_user');

    // Let widget finish animations
    await tester.pumpAndSettle();

    // SaveUsernamePage should exist
    expect(find.byType(SaveUsernamePage), findsOneWidget);

    // Tap next programmatically
    final savePage = tester.widget<SaveUsernamePage>(
      find.byType(SaveUsernamePage),
    );
    savePage.callNextPage;

    // Let widget animate to next page
    await tester.pumpAndSettle();

    // Now we should be on RedeemInvitationsPage
    expect(find.byType(RedeemInvitationsPage), findsOneWidget);
  });

  testWidgets('Page indicator shows correct number of dots', (tester) async {
    await createWidgetUnderTest(tester: tester, username: 'test_user');
    await tester.pumpAndSettle();

    // Count number of indicator dots
    final indicatorDots = find.byWidgetPredicate(
      (widget) => widget is Container && widget.decoration is BoxDecoration,
    );

    // 5 onboarding + permissions (may vary) + analytics
    expect(indicatorDots.evaluate().length, greaterThanOrEqualTo(6));
  });
}
