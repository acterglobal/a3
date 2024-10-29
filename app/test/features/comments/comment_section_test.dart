import 'package:acter/features/comments/widgets/comments_section_widget.dart';
import 'package:acter/features/comments/widgets/skeletons/comment_list_skeleton_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mock_data/mock_comments_manager.dart';
import 'mock_providers/comment_mock_providers.dart';

void main() {
  late MockAsyncCommentsManagerNotifier mockNotifier;
  late MockCommentsManager mockCommentsManager;

  setUp(() {
    mockNotifier = MockAsyncCommentsManagerNotifier();
    mockCommentsManager = MockCommentsManager();
  });

  testWidgets('displays loading skeleton when loading', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Material(
            child: CommentsSectionWidget(
              manager: Future.value(mockCommentsManager),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CommentListSkeletonWidget), findsOneWidget);
  });
}
