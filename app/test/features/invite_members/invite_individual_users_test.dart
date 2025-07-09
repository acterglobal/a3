import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acter/features/invite_members/pages/invite_individual_users.dart';
import 'package:acter/features/member/providers/invite_providers.dart';
import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/invite_members/widgets/direct_invite.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../helpers/test_util.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> createWidgetUnderTest({
    required WidgetTester tester,
    String roomId = 'test_room',
    bool isFullPageMode = true,
    String? searchValue,
  }) async {
    await tester.pumpProviderWidget(
      overrides: [
        if (searchValue != null)
          userSearchValueProvider.overrideWith((_) => searchValue),
      ],
      child: MaterialApp(
        localizationsDelegates: [
          L10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: L10n.supportedLocales,
        home: InviteIndividualUsers(
          roomId: roomId,
          isFullPageMode: isFullPageMode,
        ),
      ),
    );
    await tester.pump();
  }

  group('InviteIndividualUsers Widget Tests', () {
    testWidgets('renders correctly with isFullPageMode true', (WidgetTester tester) async {
      await createWidgetUnderTest(tester: tester);

      // Get the context and L10n instance
      final BuildContext context = tester.element(find.byType(InviteIndividualUsers));
      final lang = L10n.of(context);

      // Verify app bar is present
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text(lang.inviteIndividualUsersTitle), findsOneWidget);

      // Verify search widget is present
      expect(find.byType(ActerSearchWidget), findsOneWidget);
    });

    testWidgets('renders correctly with isFullPageMode false', (WidgetTester tester) async {
      await createWidgetUnderTest(
        tester: tester,
        isFullPageMode: false,
      );

      // Get the context and L10n instance
      final BuildContext context = tester.element(find.byType(InviteIndividualUsers));
      final lang = L10n.of(context);

      // Verify app bar is not present
      expect(find.byType(AppBar), findsNothing);

      // Verify next button is present
      expect(find.byType(ActerPrimaryActionButton), findsOneWidget);
      expect(find.text(lang.done), findsOneWidget);

      // Test next button functionality
      await tester.tap(find.byType(ActerPrimaryActionButton));
      await tester.pumpAndSettle();
    });

    testWidgets('search functionality updates provider', (WidgetTester tester) async {
      await createWidgetUnderTest(
        tester: tester,
        searchValue: null,
      );

      // Find search field and enter text
      final searchField = find.byType(ActerSearchWidget);
      await tester.enterText(searchField, '@testuser:matrix.org');
      await tester.pump();

      // Verify the search value was updated by checking if DirectInvite is shown
      expect(find.byType(DirectInvite), findsNWidgets(2));
    });

    group('Direct Invite Tests', () {
      testWidgets('shows direct invite for valid matrix ID with @', (WidgetTester tester) async {
        await createWidgetUnderTest(
          tester: tester,
          searchValue: '@testuser:matrix.org',
        );

        expect(find.byType(DirectInvite), findsNWidgets(2));
      });

      testWidgets('shows direct invite for valid matrix ID with spaces', (WidgetTester tester) async {
        await createWidgetUnderTest(
          tester: tester,
          searchValue: '  @testuser:matrix.org  ',
        );

        expect(find.byType(DirectInvite), findsNWidgets(2));
      });

      testWidgets('does not show direct invite for invalid matrix ID format', (WidgetTester tester) async {
        await createWidgetUnderTest(
          tester: tester,
          searchValue: 'invalid@user',
        );

        expect(find.byType(DirectInvite), findsNothing);
      });

      testWidgets('does not show direct invite for empty search', (WidgetTester tester) async {
        await createWidgetUnderTest(
          tester: tester,
          searchValue: '',
        );

        expect(find.byType(DirectInvite), findsNothing);
      });

      testWidgets('does not show direct invite for whitespace only', (WidgetTester tester) async {
        await createWidgetUnderTest(
          tester: tester,
          searchValue: '   ',
        );

        expect(find.byType(DirectInvite), findsNothing);
      });

      testWidgets('shows direct invite for valid matrix ID with custom domain', (WidgetTester tester) async {
        await createWidgetUnderTest(
          tester: tester,
          searchValue: '@user:custom.domain',
        );

        expect(find.byType(DirectInvite), findsNWidgets(2));
      });

      testWidgets('shows direct invite for valid matrix ID with subdomain', (WidgetTester tester) async {
        await createWidgetUnderTest(
          tester: tester,
          searchValue: '@user:sub.domain.com',
        );

        expect(find.byType(DirectInvite), findsNWidgets(2));
      });

      testWidgets('shows direct invite for any input with : and .', (WidgetTester tester) async {
        await createWidgetUnderTest(
          tester: tester,
          searchValue: '@user:invalid',
        );

        expect(find.byType(DirectInvite), findsNWidgets(2));
      });

      testWidgets('shows direct invite for input with special characters', (WidgetTester tester) async {
        await createWidgetUnderTest(
          tester: tester,
          searchValue: '@user@name:matrix.org',
        );

        expect(find.byType(DirectInvite), findsNWidgets(2));
      });

      testWidgets('shows direct invite for username without @ prefix', (WidgetTester tester) async {
        await createWidgetUnderTest(
          tester: tester,
          searchValue: 'testuser:matrix.org',
        );

        expect(find.byType(DirectInvite), findsOneWidget);
      });
    });
  });
}