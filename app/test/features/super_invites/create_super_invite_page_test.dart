import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/super_invites/pages/create_super_invite_page.dart';
import 'package:acter/features/super_invites/providers/super_invites_providers.dart';
import 'package:acter/features/super_invites/widgets/invite_list_item.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/mock_room_providers.dart';
import '../../helpers/test_util.dart';
import 'mock_data/mock_super_invites.dart';

void main() {
  late SuperInviteToken mockToken;

  setUp(() {
    mockToken = MockSuperInviteToken();
  });
  group('Create/Edit Super Invite Tests', () {
    // Helper function to create the widget under test
    Future<void> createWidgetUnderTest({
      required WidgetTester tester,
      SuperInviteToken? token,
    }) async {
      await tester.pumpProviderWidget(
        overrides: [
          maybeRoomProvider.overrideWith(() => MockAsyncMaybeRoomNotifier()),
          superInvitesProvider.overrideWith((invite) => MockSuperInvites()),
        ],
        child: CreateSuperInvitePage(token: token),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders CreateSuperInvitePage in create mode', (tester) async {
      await createWidgetUnderTest(tester: tester);

      expect(find.text('Create Invite Code'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.byKey(CreateSuperInvitePage.submitBtn), findsOneWidget);
    });

    testWidgets('renders CreateSuperInvitePage in edit mode', (tester) async {
      await createWidgetUnderTest(tester: tester, token: mockToken);

      expect(find.text('Edit Invite Code'), findsOneWidget);
      expect(find.text('test_invite_code'), findsOneWidget);
      expect(find.byType(InviteListItem), findsOneWidget);
      expect(find.byKey(CreateSuperInvitePage.deleteBtn), findsOneWidget);
    });
  });
}
