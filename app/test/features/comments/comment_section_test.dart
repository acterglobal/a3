import 'package:acter/features/comments/widgets/comments_section_widget.dart';
import 'package:acter/features/comments/widgets/skeletons/comment_list_skeleton_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/test_util.dart';
import 'mock_data/mock_comments_manager.dart';

void main() {
  late MockCommentsManager mockCommentsManager;

  setUp(() {
    mockCommentsManager = MockCommentsManager(fakeRoomId: 'roomId');
  });

  testWidgets('displays loading skeleton when loading', (tester) async {
    await tester.pumpProviderWidget(
      child: CommentsSectionWidget(
        manager: Future.value(mockCommentsManager),
      ),
    );

    expect(find.byType(CommentListSkeletonWidget), findsOneWidget);
  });
}
