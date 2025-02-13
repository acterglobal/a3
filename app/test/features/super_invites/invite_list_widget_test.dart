import 'package:acter/features/super_invites/providers/super_invites_providers.dart';
import 'package:acter/features/super_invites/widgets/invite_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/test_util.dart';
import 'invite_list_item_widget_test.dart';
import 'mock_data/mock_super_invites.dart';

void main() {
  group('InviteList Widget Tests', () {
    // Helper function to create the widget under test
    Future<void> createWidgetUnderTest({
      required WidgetTester tester,
      required List<Override> overrides,
    }) async {
      await tester.pumpProviderWidget(
        overrides: overrides,
        child: InviteListWidget(),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Empty state', (tester) async {
      final override = superInvitesTokensProvider.overrideWith((list) => []);
      await createWidgetUnderTest(tester: tester, overrides: [override]);
      await tester.pumpAndSettle();
      expect(find.byType(ListView), findsNothing);
    });
    testWidgets('List of invites available', (tester) async {
      final override = superInvitesTokensProvider.overrideWith((list) => [
            MockSuperInviteToken(),
            MockSuperInviteToken(),
          ]);
      await createWidgetUnderTest(tester: tester, overrides: [override]);
      await tester.pumpAndSettle();
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
