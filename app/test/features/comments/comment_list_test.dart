import 'package:acter/features/comments/widgets/comment_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:acter/features/comments/providers/comments_providers.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:acter/features/comments/widgets/comment_list_empty_state_widget.dart';
import 'mock_data/mock_comments_manager.dart';

void main() {
  testWidgets('displays empty state when there are no comments',
      (tester) async {
    // Arrange
    final mockCommentsManager = MockCommentsManager();

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
}
