import 'package:acter/features/comments/widgets/comment_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/features/comments/providers/comments_providers.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:acter/features/comments/widgets/comment_list_empty_state_widget.dart';
import '../../common/mock_data/mock_user_id.dart';
import '../../helpers/error_helpers.dart';
import 'mock_data/mock_comment.dart';
import 'mock_data/mock_comments_manager.dart';
import 'mock_data/mock_message_content.dart';

void main() {
  testWidgets('displays empty state when there are no comments',
      (tester) async {
    // Arrange
    final mockCommentsManager = MockCommentsManager(fakeRoomId: 'roomId');

    // Build the widget tree with the mocked provider
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          commentsListProvider.overrideWith((ref, manager) async => []),
        ],
        child: MaterialApp(
          localizationsDelegates: const [L10n.delegate],
          home: Scaffold(
            body: CommentListWidget(
              manager: mockCommentsManager, // Provide the mock manager
            ),
          ),
        ),
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
    final mockCommentsManager = MockCommentsManager(fakeRoomId: 'roomId');

    // Build the widget tree with the mocked provider
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          commentsListProvider
              .overrideWith((ref, manager) async => throw 'Some Error'),
        ],
        child: MaterialApp(
          localizationsDelegates: const [L10n.delegate],
          home: Scaffold(
            body: CommentListWidget(
              manager: mockCommentsManager, // Provide the mock manager
            ),
          ),
        ),
      ),
    );
    await tester.ensureErrorPageWorks();
  });

  testWidgets(
      'displays error state when there are issue in loading comment list and also test retry',
      (tester) async {
    bool shouldFail = true;

    // Arrange
    final mockCommentsManager = MockCommentsManager(fakeRoomId: 'roomId');

    // Build the widget tree with the mocked provider
    await tester.pumpWidget(
      ProviderScope(
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
        child: MaterialApp(
          localizationsDelegates: const [L10n.delegate],
          home: Scaffold(
            body: CommentListWidget(
              manager: mockCommentsManager, // Provide the mock manager
            ),
          ),
        ),
      ),
    );
    await tester.ensureErrorPageWithRetryWorks();
  });

  testWidgets('displays list state when there are comments', (tester) async {
    // Arrange
    final mockCommentsManager = MockCommentsManager(fakeRoomId: 'roomId');
    final mockUser1 = MockComment(
      fakeSender: MockUserId(),
      fakeMsgContent: MockMsgContent(bodyText: 'message 1'),
      fakeOriginServerTs: DateTime.now().millisecondsSinceEpoch,
    );
    final mockUser2 = MockComment(
      fakeSender: MockUserId(),
      fakeMsgContent: MockMsgContent(bodyText: 'message 2'),
      fakeOriginServerTs: DateTime.now().millisecondsSinceEpoch,
    );
    final mockUser3 = MockComment(
      fakeSender: MockUserId(),
      fakeMsgContent: MockMsgContent(bodyText: 'message 3'),
      fakeOriginServerTs: DateTime.now().millisecondsSinceEpoch,
    );

    // Build the widget tree with the mocked provider
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          commentsListProvider.overrideWith(
            (ref, manager) async => [
              mockUser1,
              mockUser2,
              mockUser3,
            ],
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: const [L10n.delegate],
          home: Scaffold(
            body: CommentListWidget(
              manager: mockCommentsManager, // Provide the mock manager
            ),
          ),
        ),
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
}
