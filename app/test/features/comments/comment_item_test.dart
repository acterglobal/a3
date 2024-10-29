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
import '../../common/mock_providers/mock_avatarinfo_provider.dart';


void main() {
  late MockComment mockComment;
  late MockCommentsManager mockCommentsManager;
  late MockAvatarInfo mockAvatarInfo;
  late MockUserId mockUserId;
  late MockMsgContent mockMsgContent;

  setUp(() {
    mockComment = MockComment();
    mockCommentsManager = MockCommentsManager();
    mockAvatarInfo = MockAvatarInfo();
    mockUserId = MockUserId();
    mockMsgContent = MockMsgContent();

    // Mock the values expected by the widget
    when(() => mockCommentsManager.roomIdStr()).thenReturn('roomId');
    when(() => mockComment.sender()).thenReturn(mockUserId);
    when(() => mockComment.msgContent()).thenReturn(mockMsgContent);
    when(() => mockMsgContent.body()).thenReturn('This is a test message');
    when(() => mockComment.originServerTs())
        .thenReturn(DateTime.now().millisecondsSinceEpoch);
    when(() => mockAvatarInfo.displayName).thenReturn('Test User');
    when(() => mockAvatarInfo.uniqueId).thenReturn('unique-avatar-id');
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
