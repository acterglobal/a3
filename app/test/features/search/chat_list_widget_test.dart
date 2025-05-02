import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:acter/features/search/widgets/chat_list_widget.dart';
import 'package:acter/features/chat/widgets/convo_card.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/mock_a3sdk.dart';
import '../../helpers/test_util.dart';

void main() {
  group('Chat List', () {
    testWidgets('displays empty state when there are no chats', (tester) async {
      //Arrange:
      var emptyState = Text('empty state');
      final provider = Provider<List<Convo>>((ref) => []);

      // Build the widget tree with an empty provider
      await tester.pumpProviderWidget(
        child: ChatListWidget(
          chatListProvider: provider,
          emptyState: emptyState,
        ),
      );

      // Act
      await tester.pumpAndSettle(); // Allow the widget to settle

      // Assert
      expect(
        find.text('empty state'),
        findsOneWidget,
      ); // Ensure the empty state widget is displayed
    });

    testWidgets('displays list of chats when data is available', (
      tester,
    ) async {
      // Arrange
      final convo1 = MockConvo('roomId-1');
      final convo2 = MockConvo('roomId-2');
      final convo3 = MockConvo('roomId-3');

      final provider = Provider<List<Convo>>((ref) => [convo1, convo2, convo3]);

      //Arrange:
      var emptyState = Text('empty state');

      // Build the widget tree with the mocked provider
      await tester.pumpProviderWidget(
        overrides: [
          roomMembershipProvider.overrideWith((a, b) => null),
          isBookmarkedProvider.overrideWith((a, b) => false),
          roomDisplayNameProvider.overrideWith((a, b) => 'test'),
        ],
        child: ChatListWidget(
          chatListProvider: provider,
          emptyState: emptyState,
        ),
      );
      // Initial build
      await tester.pump();

      // Wait for async operations
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.byType(ConvoCard),
        findsNWidgets(3),
        reason: 'Should find 3 ConvoCard widgets',
      );
    });
  });
}
