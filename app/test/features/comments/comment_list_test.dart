import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/comments/providers/comments_providers.dart';
import 'package:acter/features/comments/widgets/comment_list_empty_state_widget.dart';
import 'package:acter/features/comments/widgets/comment_list_widget.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../common/mock_data/mock_user_id.dart';
import '../../helpers/error_helpers.dart';
import '../../helpers/test_util.dart';
import 'mock_data/mock_comment.dart';
import 'mock_data/mock_comments_manager.dart';
import 'mock_data/mock_message_content.dart';

void main() {
  group('Comment List', () {
    testWidgets('displays empty state when there are no comments', (
      tester,
    ) async {
      // Arrange
      final mockCommentsManager = MockCommentsManager();

      // Build the widget tree with the mocked provider
      await tester.pumpProviderWidget(
        overrides: [
          commentsListProvider.overrideWith((ref, manager) async => []),
        ],
        child: CommentListWidget(
          manager: mockCommentsManager, // Provide the mock manager
        ),
      );

      // Act
      await tester.pumpAndSettle(); // Allow the widget to settle

      // Assert
      expect(
        find.byType(CommentListEmptyStateWidget),
        findsOneWidget,
      ); // Ensure the empty state widget is displayed
    });

    testWidgets(
      'displays error state when there are issue in loading comment list',
      (tester) async {
        // Arrange
        final mockCommentsManager = MockCommentsManager();

        // Build the widget tree with the mocked provider
        await tester.pumpProviderWidget(
          overrides: [
            commentsListProvider.overrideWith(
              (ref, manager) async => throw 'Some Error',
            ),
          ],
          child: CommentListWidget(
            manager: mockCommentsManager, // Provide the mock manager
          ),
        );
        await tester.ensureErrorPageWorks();
      },
    );

    testWidgets(
      'displays error state when there are issue in loading comment list and also test retry',
      (tester) async {
        bool shouldFail = true;

        // Arrange
        final mockCommentsManager = MockCommentsManager();

        // Build the widget tree with the mocked provider
        await tester.pumpProviderWidget(
          overrides: [
            commentsListProvider.overrideWith((ref, manager) async {
              if (shouldFail) {
                shouldFail = false;
                throw 'Some Error';
              } else {
                return [];
              }
            }),
          ],
          child: CommentListWidget(
            manager: mockCommentsManager, // Provide the mock manager
          ),
        );
        await tester.ensureErrorPageWithRetryWorks();
      },
    );

    testWidgets('displays list state when there are comments', (tester) async {
      // Arrange

      final mockComment1 = MockComment(
        fakeSender: MockUserId('user-1'),
        fakeMsgContent: MockMsgContent(bodyText: 'message 1'),
        fakeOriginServerTs: DateTime.now().millisecondsSinceEpoch,
      );
      final mockComment2 = MockComment(
        fakeSender: MockUserId('user-2'),
        fakeMsgContent: MockMsgContent(bodyText: 'message 2'),
        fakeOriginServerTs: DateTime.now().millisecondsSinceEpoch,
      );
      final mockComment3 = MockComment(
        fakeSender: MockUserId('user-3'),
        fakeMsgContent: MockMsgContent(bodyText: 'message 3'),
        fakeOriginServerTs: DateTime.now().millisecondsSinceEpoch,
      );

      final mockCommentsManager = MockCommentsManager();
      when(() => mockCommentsManager.roomIdStr()).thenReturn('roomId');

      // Build the widget tree with the mocked provider
      await tester.pumpProviderWidget(
        overrides: [
          memberAvatarInfoProvider.overrideWith(
            (a, i) => const AvatarInfo(uniqueId: 'uniqueId'),
          ),
          commentsListProvider.overrideWith(
            (ref, manager) async => [mockComment1, mockComment2, mockComment3],
          ),
        ],
        child: CommentListWidget(
          manager: mockCommentsManager, // Provide the mock manager
        ),
      );
      // Act
      await tester.pumpAndSettle(); // Allow the widget to settle

      // Assert
      expect(
        find.byType(CommentListEmptyStateWidget),
        findsNothing,
      ); // Ensure the empty state widget is displayed
    });
  });
}
