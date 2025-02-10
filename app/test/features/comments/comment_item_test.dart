import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:acter/features/comments/widgets/comment_item_widget.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../common/mock_data/mock_avatar_info.dart';
import '../../common/mock_data/mock_user_id.dart';
import '../../helpers/test_util.dart';
import 'mock_data/mock_comment.dart';
import 'mock_data/mock_comments_manager.dart';
import 'mock_data/mock_message_content.dart';

void main() {
  late MockComment mockComment;
  late MockCommentsManager mockCommentsManager;
  late MockAvatarInfo mockAvatarInfo;

  setUp(() {
    mockCommentsManager = MockCommentsManager();
    mockComment = MockComment(
      fakeSender: MockUserId('user-1'),
      fakeMsgContent: MockMsgContent(bodyText: 'This is a test message'),
      fakeOriginServerTs: DateTime.now().millisecondsSinceEpoch,
    );
    mockAvatarInfo = MockAvatarInfo(uniqueId: 'user-1');

    // Mock the values expected by the widget
    when(() => mockCommentsManager.roomIdStr()).thenReturn('roomId');
    when(() => mockAvatarInfo.displayName).thenReturn('Test User');
  });

  testWidgets(
      'renders CommentItemWidget with avatar, name, content, and timestamp',
      (WidgetTester tester) async {
    // Wrap in ProviderScope and override the necessary providers
    await tester.pumpProviderWidget(
      overrides: [
        memberAvatarInfoProvider
            .overrideWith((ref, MemberInfo memberInfo) => mockAvatarInfo),
      ],
      child: CommentItemWidget(
        comment: mockComment,
        manager: mockCommentsManager,
      ),
    );

    // Verify all expected widgets are displayed
    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('This is a test message'), findsOneWidget);
    expect(find.byType(ActerAvatar), findsOneWidget);
    expect(
      find.byType(RenderHtml),
      findsNothing,
    ); // Because formattedBody is null
  });
}
