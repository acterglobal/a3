import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acter/features/invite_members/pages/invite_page.dart';
import 'package:acter/common/toolkit/menu_item_widget.dart';
import 'package:acter/features/invite_members/widgets/invite_code_ui.dart';
import 'package:acter/features/super_invites/providers/super_invites_providers.dart';
import 'package:acter/common/widgets/room/room_profile_header.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../../helpers/test_util.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InvitePage Widget Tests', () {
    testWidgets('renders correctly without callNextPage and showInviteSpaceMembers is true', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          hasSuperTokensAccess.overrideWith((_) => false),
        ],
        child: MaterialApp(
          localizationsDelegates: [
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: L10n.supportedLocales,
          home: const InvitePage(roomId: 'test_room', showInviteSpaceMembers: true),
        ),
      );

      // Get the context and L10n instance
      final BuildContext context = tester.element(find.byType(InvitePage));
      final lang = L10n.of(context);

      // Verify app bar is present
      expect(find.byType(AppBar), findsOneWidget);
      
      // Verify header components
      expect(find.byType(RoomProfileHeader), findsOneWidget);
      expect(find.text(lang.invite), findsOneWidget);
      expect(find.text(lang.spaceInviteDescription), findsOneWidget);

      // Verify invite methods
      expect(find.byType(MenuItemWidget), findsNWidgets(2));
      expect(find.text(lang.inviteSpaceMembersTitle), findsOneWidget);
      expect(find.text(lang.inviteIndividualUsersTitle), findsOneWidget);

      // Verify invite code UI is not shown when no super tokens access
      expect(find.byType(InviteCodeUI), findsNothing);
    });

    testWidgets('renders correctly with callNextPage and showInviteSpaceMembers is false', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          hasSuperTokensAccess.overrideWith((_) => false),
        ],
        child: MaterialApp(
          localizationsDelegates: [
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: L10n.supportedLocales,
          home: InvitePage(
            roomId: 'test_room',
            callNextPage: () => true,
            showInviteSpaceMembers: false,
          ),
        ),
      );

      // Get the context and L10n instance
      final BuildContext context = tester.element(find.byType(InvitePage));
      final lang = L10n.of(context);

      // Verify only individual invite option is shown
      expect(find.byType(MenuItemWidget), findsOneWidget);
      expect(find.text(lang.inviteIndividualUsersTitle), findsOneWidget);
      expect(find.text(lang.inviteSpaceMembersTitle), findsNothing);
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.text(lang.skip), findsOneWidget);
      expect(find.byType(ActerPrimaryActionButton), findsOneWidget);
      expect(find.text(lang.continueLabel), findsOneWidget);
    });

    testWidgets('shows invite code UI when has super tokens access', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          superInvitesTokensProvider.overrideWith((_) => Future.value([])),
          hasSuperTokensAccess.overrideWith((_) => true),
        ],
        child: MaterialApp(
          localizationsDelegates: [
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: L10n.supportedLocales,
          home: const InvitePage(roomId: 'test_room'),
        ),
      );

      // Wait for the widget to rebuild
      await tester.pumpAndSettle();

      // Get the context and L10n instance
      final BuildContext context = tester.element(find.byType(InvitePage));
      final lang = L10n.of(context);

      // Verify invite code UI is shown
      expect(find.byType(InviteCodeUI), findsOneWidget);
      expect(find.text(lang.inviteJoinActer), findsOneWidget);
      expect(find.text(lang.inviteJoinActerDescription), findsOneWidget);
    });

    testWidgets('pending button is present in app bar when showInviteSpaceMembers is true', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          hasSuperTokensAccess.overrideWith((_) => false),
        ],
        child: MaterialApp(
          localizationsDelegates: [
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: L10n.supportedLocales,
          home: const InvitePage(roomId: 'test_room', showInviteSpaceMembers: true),
        ),
      );

      // Get the context and L10n instance
      final BuildContext context = tester.element(find.byType(InvitePage));
      final lang = L10n.of(context);

      // Verify pending button is present
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byIcon(Icons.person_outline_outlined), findsOneWidget);
      expect(find.text(lang.pending), findsOneWidget);
    });

    testWidgets('pending button is not present in app bar when showInviteSpaceMembers is false', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          hasSuperTokensAccess.overrideWith((_) => false),
        ],
        child: MaterialApp(
          localizationsDelegates: [
            L10n.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: L10n.supportedLocales,
          home: const InvitePage(roomId: 'test_room', showInviteSpaceMembers: false),
        ),  
      );

      // Get the context and L10n instance
      final BuildContext context = tester.element(find.byType(InvitePage));
      final lang = L10n.of(context);

      expect(find.text(lang.pending), findsNothing);
      
    });   
  });
}