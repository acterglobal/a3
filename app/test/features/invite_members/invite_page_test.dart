import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acter/features/invite_members/pages/invite_page.dart';
import 'package:acter/common/toolkit/menu_item_widget.dart';
import 'package:acter/features/invite_members/widgets/invite_code_ui.dart';
import 'package:acter/features/super_invites/providers/super_invites_providers.dart';
import 'package:acter/common/widgets/room/room_profile_header.dart';
import '../../helpers/test_util.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InvitePage Widget Tests', () {
    testWidgets('renders correctly without callNextPage', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          hasSuperTokensAccess.overrideWith((_) => false),
        ],
        child: const InvitePage(roomId: 'test_room'),
      );

      // Verify app bar is present
      expect(find.byType(AppBar), findsOneWidget);
      
      // Verify header components
      expect(find.byType(RoomProfileHeader), findsOneWidget);
      expect(find.text('Invite'), findsOneWidget);
      expect(find.text('Anyone you would like to invite to this space?'), findsOneWidget);

      // Verify invite methods
      expect(find.byType(MenuItemWidget), findsNWidgets(2));
      expect(find.text('Invite Space Members'), findsOneWidget);
      expect(find.text('Invite Individual Users'), findsOneWidget);

      // Verify invite code UI is not shown when no super tokens access
      expect(find.byType(InviteCodeUI), findsNothing);
    });

    testWidgets('renders correctly with callNextPage', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          hasSuperTokensAccess.overrideWith((_) => false),
        ],
        child: InvitePage(
          roomId: 'test_room',
          callNextPage: () => true,
        ),
      );

      // Verify app bar is not present
      expect(find.byType(AppBar), findsNothing);

      // Verify only individual invite option is shown
      expect(find.byType(MenuItemWidget), findsOneWidget);
      expect(find.text('Invite Individual Users'), findsOneWidget);
      expect(find.text('Invite Space Members'), findsNothing);
    });

    testWidgets('shows invite code UI when has super tokens access', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          superInvitesTokensProvider.overrideWith((_) => Future.value([])),
          hasSuperTokensAccess.overrideWith((_) => true),
        ],
        child: const InvitePage(roomId: 'test_room'),
      );

      // Wait for the widget to rebuild
      await tester.pumpAndSettle();

      // Verify invite code UI is shown
      expect(find.byType(InviteCodeUI), findsOneWidget);
      expect(find.text('Invite to join Acter'), findsOneWidget);
      expect(
        find.text('You can invite people to join Acter and automatically join this space with a custom registration code and share that with them'),
        findsOneWidget,
      );
    });

    testWidgets('pending button is present in app bar', (WidgetTester tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          hasSuperTokensAccess.overrideWith((_) => false),
        ],
        child: const InvitePage(roomId: 'test_room'),
      );

      // Verify pending button is present
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline_outlined), findsOneWidget);
    });
  });
}