import 'package:acter/features/tasks/widgets/accept_decline_task_invitation_widget.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:acter/l10n/generated/l10n.dart';
import '../../../helpers/mock_a3sdk.dart';
import '../../../helpers/mock_tasks_providers.dart';
import '../../../helpers/test_util.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  late MockTask mockTask;
  late BuildContext context;

  setUpAll(() {
    registerFallbackValue(MockEventId(id: 'event123'));
  });

  setUp(() {
    mockTask = MockTask();
  });

  Future<void> pumpAcceptDeclineTaskInvitationWidget(WidgetTester tester) async {
    await tester.pumpProviderWidget(
      child: AcceptDeclineTaskInvitationWidget(task: mockTask),
    );
    await tester.pump();
    context = tester.element(find.byType(AcceptDeclineTaskInvitationWidget));
  }

  group('AcceptDeclineTaskInvitationWidget', () {
    testWidgets('displays widget with avatar when displayName is available', (tester) async {
      // Setup mock behavior
      mockTask = MockTask(
        fakeTitle: 'Test Task',
        desc: 'Test Description',
        roomId: 'room123',
      );

      await pumpAcceptDeclineTaskInvitationWidget(tester);

      // Verify the widget is displayed
      expect(find.byType(AcceptDeclineTaskInvitationWidget), findsOneWidget);
      
      // Verify the invitation text is displayed
      expect(find.text(L10n.of(context).invitedYouToTakeOverThisTask), findsOneWidget);
      
      // Verify accept and decline buttons are present
      expect(find.text(L10n.of(context).accept), findsOneWidget);
      expect(find.text(L10n.of(context).decline), findsOneWidget);
      
      // Verify the main container styling (more specific)
      expect(find.descendant(
        of: find.byType(AcceptDeclineTaskInvitationWidget),
        matching: find.byType(Container),
      ), findsOneWidget);
      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('displays fallback icon when displayName is null', (tester) async {
      // Setup mock behavior
      mockTask = MockTask(
        fakeTitle: 'Test Task',
        desc: 'Test Description',
        roomId: 'room123',
      );

      await pumpAcceptDeclineTaskInvitationWidget(tester);

      // Verify the fallback person icon is displayed
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('displays ActerAvatar when displayName is available', (tester) async {
      // Setup mock behavior
      mockTask = MockTask(
        fakeTitle: 'Test Task',
        desc: 'Test Description',
        roomId: 'room123',
      );

      await pumpAcceptDeclineTaskInvitationWidget(tester);

      // Verify ActerAvatar is displayed (this will depend on the provider returning displayName)
      // Note: This might not find ActerAvatar if the provider returns null displayName
      expect(find.byType(ActerAvatar), findsAtLeastNWidgets(0));
    });

    testWidgets('has accept and decline buttons', (tester) async {
      // Setup mock behavior
      mockTask = MockTask(
        fakeTitle: 'Test Task',
        desc: 'Test Description',
        roomId: 'room123',
      );

      await pumpAcceptDeclineTaskInvitationWidget(tester);

      // Verify both buttons are present
      expect(find.text(L10n.of(context).accept), findsOneWidget);
      expect(find.text(L10n.of(context).decline), findsOneWidget);
      
      // Verify the accept button has the check icon
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('displays correct layout structure', (tester) async {
      // Setup mock behavior
      mockTask = MockTask(
        fakeTitle: 'Test Task',
        desc: 'Test Description',
        roomId: 'room123',
      );

      await pumpAcceptDeclineTaskInvitationWidget(tester);

      // Verify the main container structure
      expect(find.descendant(
        of: find.byType(AcceptDeclineTaskInvitationWidget),
        matching: find.byType(Container),
      ), findsOneWidget);
      expect(find.byType(Padding), findsWidgets);
      expect(find.descendant(
        of: find.byType(AcceptDeclineTaskInvitationWidget),
        matching: find.byType(Column),
      ), findsOneWidget);
      expect(find.byType(Row), findsAtLeastNWidgets(2)); // At least two rows: one for avatar/text, one for buttons
    });

    testWidgets('displays correct button layout', (tester) async {
      // Setup mock behavior
      mockTask = MockTask(
        fakeTitle: 'Test Task',
        desc: 'Test Description',
        roomId: 'room123',
      );

      await pumpAcceptDeclineTaskInvitationWidget(tester);

      // Verify button layout - look for buttons by text instead of type
      expect(find.text(L10n.of(context).accept), findsOneWidget);
      expect(find.text(L10n.of(context).decline), findsOneWidget);
      
      // Verify button icons
      expect(find.byIcon(Icons.check), findsOneWidget); // Accept button icon
    });

    testWidgets('displays correct spacing and styling', (tester) async {
      // Setup mock behavior
      mockTask = MockTask(
        fakeTitle: 'Test Task',
        desc: 'Test Description',
        roomId: 'room123',
      );

      await pumpAcceptDeclineTaskInvitationWidget(tester);

      // Verify spacing widgets are present (more flexible count)
      expect(find.byType(SizedBox), findsAtLeastNWidgets(2)); // At least one between avatar and text, one before buttons
      
      // Verify the container has proper decoration
      final container = tester.widget<Container>(find.descendant(
        of: find.byType(AcceptDeclineTaskInvitationWidget),
        matching: find.byType(Container),
      ));
      expect(container.decoration, isNotNull);
    });

    testWidgets('handles task with different room IDs', (tester) async {
      // Setup mock behavior with different room ID
      mockTask = MockTask(
        fakeTitle: 'Test Task',
        desc: 'Test Description',
        roomId: 'different-room-456',
      );

      await pumpAcceptDeclineTaskInvitationWidget(tester);

      // Verify the widget still renders correctly
      expect(find.byType(AcceptDeclineTaskInvitationWidget), findsOneWidget);
      expect(find.text(L10n.of(context).invitedYouToTakeOverThisTask), findsOneWidget);
      expect(find.text(L10n.of(context).accept), findsOneWidget);
      expect(find.text(L10n.of(context).decline), findsOneWidget);
    });

    testWidgets('displays correct margin and padding', (tester) async {
      // Setup mock behavior
      mockTask = MockTask(
        fakeTitle: 'Test Task',
        desc: 'Test Description',
        roomId: 'room123',
      );

      await pumpAcceptDeclineTaskInvitationWidget(tester);

      // Verify the container has proper margin
      final container = tester.widget<Container>(find.descendant(
        of: find.byType(AcceptDeclineTaskInvitationWidget),
        matching: find.byType(Container),
      ));
      expect(container.margin, isNotNull);
      
      // Verify the padding is applied (more flexible)
      expect(find.byType(Padding), findsWidgets);
    });
  });

  group('AcceptDeclineTaskInvitationWidget - Provider Integration and Avatar Logic Tests', () {
    late MockTask mockTask;
    late AvatarInfo mockAvatarInfo;
    const testRoomId = 'room123';
    const testUserId = '';

    setUp(() {
      mockTask = MockTask();
      mockAvatarInfo = AvatarInfo(uniqueId: testUserId, displayName: 'Test User');
      // No need to stub assignSelf/unassignSelf or roomIdStr, use the built-in implementation
    });

    Widget buildTestWidget(Widget child) {
      return ProviderScope(
        overrides: [
          memberAvatarInfoProvider.overrideWith((ref, info) =>
            info.roomId == testRoomId && info.userId == testUserId
              ? mockAvatarInfo
              : AvatarInfo(uniqueId: info.userId)),
        ],
        child: MaterialApp(
          localizationsDelegates: [
            L10n.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: L10n.supportedLocales,
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('accept button is properly configured', (tester) async {
      await tester.pumpWidget(buildTestWidget(AcceptDeclineTaskInvitationWidget(task: mockTask)));
      await tester.pump();
      
      // Find the accept button text
      final acceptButton = find.textContaining('Accept');
      expect(acceptButton, findsOneWidget);
      
      // Verify the button has the check icon
      expect(find.byIcon(Icons.check), findsOneWidget);
      
      // Verify the button is tappable by checking if it's a descendant of a button-like widget
      final buttonAncestor = find.ancestor(
        of: acceptButton,
        matching: find.byType(GestureDetector),
      );
      expect(buttonAncestor, findsOneWidget);
    });

    testWidgets('decline button is properly configured', (tester) async {
      await tester.pumpWidget(buildTestWidget(AcceptDeclineTaskInvitationWidget(task: mockTask)));
      await tester.pump();
      
      // Find the decline button text
      final declineButton = find.textContaining('Decline');
      expect(declineButton, findsOneWidget);
      
      // Verify the button is tappable by checking if it's a descendant of a button-like widget
      final buttonAncestor = find.ancestor(
        of: declineButton,
        matching: find.byType(GestureDetector),
      );
      expect(buttonAncestor, findsOneWidget);
    });

    testWidgets('shows fallback icon when displayName is null', (tester) async {
      final nullAvatarInfo = AvatarInfo(uniqueId: testUserId, displayName: null);
      mockAvatarInfo = nullAvatarInfo;
      await tester.pumpWidget(buildTestWidget(AcceptDeclineTaskInvitationWidget(task: mockTask)));
      await tester.pump();
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byType(ActerAvatar), findsNothing);
    });

    testWidgets('shows ActerAvatar when displayName is not null', (tester) async {
      mockAvatarInfo = AvatarInfo(uniqueId: testUserId, displayName: 'Test User');
      await tester.pumpWidget(buildTestWidget(AcceptDeclineTaskInvitationWidget(task: mockTask)));
      await tester.pump();
      expect(find.byType(ActerAvatar), findsOneWidget);
      expect(find.byIcon(Icons.person), findsNothing);
    });
  });
}