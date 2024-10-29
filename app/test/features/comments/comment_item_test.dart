import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/render_html.dart';
import 'package:acter/features/comments/widgets/comment_item_widget.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'mock_data/mock_comment.dart';
import 'mock_data/mock_comments_manager.dart';
import 'mock_data/mock_message_content.dart';
import '../../common/mock_data/mock_user_id.dart';
import '../../common/mock_data/mock_avatar_info.dart';

void main() {
  late MockComment mockComment;
  late MockCommentsManager mockCommentsManager;
  late MockAvatarInfo mockAvatarInfo;

  setUp(() {
    mockCommentsManager = MockCommentsManager(fakeRoomId: 'roomId');
    mockComment = MockComment(
      fakeSender: MockUserId(),
      fakeMsgContent: MockMsgContent(bodyText: 'This is a test message'),
      fakeOriginServerTs: DateTime.now().millisecondsSinceEpoch,
    );
    mockAvatarInfo = MockAvatarInfo();

    // Mock the values expected by the widget
    when(() => mockCommentsManager.roomIdStr()).thenReturn('roomId');
    when(() => mockAvatarInfo.displayName).thenReturn('Test User');
  });

  testWidgets(
      'renders CommentItemWidget with avatar, name, content, and timestamp',
      (WidgetTester tester) async {
    // Wrap in ProviderScope and override the necessary providers
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          memberAvatarInfoProvider
              .overrideWith((ref, MemberInfo memberInfo) => mockAvatarInfo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CommentItemWidget(
              comment: mockComment,
              manager: mockCommentsManager,
            ),
          ),
        ),
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
