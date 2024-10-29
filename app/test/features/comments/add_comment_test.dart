import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/features/comments/widgets/add_comment_widget.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import '../../common/mock_data/mock_avatar_info.dart';
import 'mock_data/mock_comments_manager.dart';

void main() {
  late MockCommentsManager mockCommentsManager;
  late MockAvatarInfo mockAvatarInfo;

  setUp(() {
    mockCommentsManager = MockCommentsManager(fakeRoomId: 'roomId');
    mockAvatarInfo = MockAvatarInfo();
  });

  testWidgets('should display avatar and comment input',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Use overrideWith for the AutoDisposeStateProvider with a mock value
          accountAvatarInfoProvider.overrideWith((ref) => mockAvatarInfo),
        ],
        child: MaterialApp(
          localizationsDelegates: const [L10n.delegate],
          builder: EasyLoading.init(),
          home: Scaffold(
            body: AddCommentWidget(manager: mockCommentsManager),
          ),
        ),
      ),
    ); // Dummy avatar info

    // Check if avatar is displayed
    expect(find.byType(ActerAvatar), findsOneWidget);

    // Check if comment input field is displayed
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('send button appears when text is entered',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Use overrideWith for the AutoDisposeStateProvider with a mock value
          accountAvatarInfoProvider.overrideWith((ref) => mockAvatarInfo),
        ],
        child: MaterialApp(
          localizationsDelegates: const [L10n.delegate],
          builder: EasyLoading.init(),
          home: Scaffold(
            body: AddCommentWidget(manager: mockCommentsManager),
          ),
        ),
      ),
    );
    // Initially, send button should not be visible
    expect(find.byKey(AddCommentWidget.addCommentButton), findsNothing);

    // Enter text in the comment box
    await tester.enterText(find.byType(TextField), 'Test comment');
    await tester.pump();

    // Send button should now be visible
    expect(find.byKey(AddCommentWidget.addCommentButton), findsOneWidget);
  });
}
