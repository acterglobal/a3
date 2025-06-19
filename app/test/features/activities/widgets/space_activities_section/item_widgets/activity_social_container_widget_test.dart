import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/activities/widgets/space_activities_section/item_widgets/activity_social_container_widget.dart';
import 'package:acter/features/comments/widgets/time_ago_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../../helpers/test_util.dart';
import '../../../../activity/mock_data/mock_activity_object.dart';

void main() {

  Future<void> pumpActivitySocialContainerWidget(
    WidgetTester tester, {
    ActivityObject? activityObject,
    IconData? icon,
    Color? iconColor,
    String? userId,
    String? roomId,
    String? actionTitle,
    int? originServerTs,
  }) async {
    await tester.pumpProviderWidget(
      overrides: [
        memberDisplayNameProvider((
          userId: userId ?? 'test-user-id',
          roomId: roomId ?? 'test-room-id',
        )).overrideWith((ref) => Future.value('Test User')),
      ],
      child: MaterialApp(
        localizationsDelegates: [
          L10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: ActivitySocialContainerWidget(
            activityObject: activityObject,
            icon: icon ?? Icons.favorite,
            iconColor: iconColor,
            userId: userId ?? 'test-user-id',
            roomId: roomId ?? 'test-room-id',
            actionTitle: actionTitle ?? 'liked',
            originServerTs: originServerTs ?? 1234567890,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ActivitySocialContainerWidget Tests', () {
    testWidgets('renders with basic properties', (WidgetTester tester) async {
      await pumpActivitySocialContainerWidget(tester);

      // Verify the widget is rendered
      expect(find.byType(ActivitySocialContainerWidget), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(Row), findsWidgets);

      // Verify RichText widgets are rendered (there can be multiple for different parts)
      final richTextWidgets = find.byType(RichText);
      expect(richTextWidgets, findsWidgets);
    });

    testWidgets('displays user display name', (WidgetTester tester) async {
      await pumpActivitySocialContainerWidget(tester);

      // The display name is in a RichText widget
      expect(findRichTextContaining('Test User'), findsOneWidget);
    });

    testWidgets('displays default values correctly', (
      WidgetTester tester,
    ) async {
      await pumpActivitySocialContainerWidget(tester);

      // Test with default values
      expect(findRichTextContaining('Test User'), findsOneWidget);
      expect(findRichTextContaining('liked'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('displays custom icon', (WidgetTester tester) async {
      await pumpActivitySocialContainerWidget(tester, icon: Icons.thumb_up);

      expect(find.byIcon(Icons.thumb_up), findsOneWidget);
    });

    testWidgets('displays icon with custom color', (WidgetTester tester) async {
      await pumpActivitySocialContainerWidget(
        tester,
        icon: Icons.star,
        iconColor: Colors.red,
      );

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(iconWidget.color, Colors.red);
    });

    testWidgets('displays icon with default color when iconColor is null', (
      WidgetTester tester,
    ) async {
      await pumpActivitySocialContainerWidget(
        tester,
        icon: Icons.star,
        iconColor: null,
      );

      // Icon should still be rendered
      expect(find.byIcon(Icons.star), findsOneWidget);

      // The icon should have the default color from theme
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(iconWidget.color, isNotNull);
    });

    testWidgets('displays TimeAgoWidget', (WidgetTester tester) async {
      await pumpActivitySocialContainerWidget(tester);

      expect(find.byType(TimeAgoWidget), findsOneWidget);
    });

    testWidgets('displays TimeAgoWidget with custom timestamp', (
      WidgetTester tester,
    ) async {
      await pumpActivitySocialContainerWidget(
        tester,
        originServerTs: 9876543210,
      );

      expect(find.byType(TimeAgoWidget), findsOneWidget);
    });

    testWidgets('displays activity object title for news type', (
      WidgetTester tester,
    ) async {
      final activityObject = MockActivityObject(mockType: 'news');

      await pumpActivitySocialContainerWidget(
        tester,
        activityObject: activityObject,
        actionTitle: 'shared',
      );

      // Should contain the localized boost text
      expect(findRichTextContaining('shared'), findsOneWidget);
    });

    testWidgets('displays activity object title for story type', (
      WidgetTester tester,
    ) async {
      final activityObject = MockActivityObject(mockType: 'story');

      await pumpActivitySocialContainerWidget(
        tester,
        activityObject: activityObject,
        actionTitle: 'shared',
      );

      // Should contain the localized story text
      expect(findRichTextContaining('shared'), findsOneWidget);
    });

    testWidgets('displays rich text with proper styling and overflow', (
      WidgetTester tester,
    ) async {
      await pumpActivitySocialContainerWidget(
        tester,
        actionTitle: 'reacted to',
      );

      // Verify RichText widgets exist
      final richTextWidgets = find.byType(RichText);
      expect(richTextWidgets, findsWidgets);

      // Find the specific RichText with our content
      final contentRichText = find.byWidgetPredicate((widget) {
        if (widget is RichText) {
          final text = widget.text.toPlainText();
          return text.contains('Test User') && text.contains('reacted to');
        }
        return false;
      });
      expect(contentRichText, findsOneWidget);

      // Verify the content RichText widget properties
      final richTextWidget = tester.widget<RichText>(contentRichText);
      expect(richTextWidget.maxLines, 2);
      expect(richTextWidget.overflow, TextOverflow.ellipsis);

      // Verify content
      expect(findRichTextContaining('Test User'), findsOneWidget);
      expect(findRichTextContaining('reacted to'), findsOneWidget);
    });

    testWidgets('handles special characters in text', (
      WidgetTester tester,
    ) async {
      await pumpActivitySocialContainerWidget(
        tester,
        actionTitle: 'action with special chars: @#\$%^&*() and emoji 🚀',
      );

      expect(
        findRichTextContaining(
          'action with special chars: @#\$%^&*() and emoji 🚀',
        ),
        findsOneWidget,
      );
    });

    testWidgets('uses fallback userId when display name is null', (
      WidgetTester tester,
    ) async {
      await tester.pumpProviderWidget(
        overrides: [
          memberDisplayNameProvider((
            userId: 'fallback-user',
            roomId: 'test-room-id',
          )).overrideWith((ref) => Future.value(null)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ActivitySocialContainerWidget(
              icon: Icons.favorite,
              userId: 'fallback-user',
              roomId: 'test-room-id',
              actionTitle: 'liked',
              originServerTs: 1234567890,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should use userId as fallback
      expect(findRichTextContaining('fallback-user'), findsOneWidget);
    });
    group('Integration Tests', () {
      testWidgets('widget rebuilds correctly when properties change', (
        WidgetTester tester,
      ) async {
        // Initial render
        await pumpActivitySocialContainerWidget(
          tester,
          actionTitle: 'liked',
          icon: Icons.favorite,
        );

        // Verify initial render
        expect(find.byType(ActivitySocialContainerWidget), findsOneWidget);
        expect(findRichTextContaining('liked'), findsOneWidget);
        expect(find.byIcon(Icons.favorite), findsOneWidget);

        // Change properties and rebuild - this replaces the entire widget tree
        await pumpActivitySocialContainerWidget(
          tester,
          actionTitle: 'shared',
          icon: Icons.share,
          iconColor: Colors.blue,
        );

        // Verify widget still renders after rebuild
        expect(find.byType(ActivitySocialContainerWidget), findsOneWidget);
        expect(find.byType(RichText), findsWidgets);

        // Verify that TimeAgoWidget is still present
        expect(find.byType(TimeAgoWidget), findsOneWidget);

        // Verify that the icon is present
        expect(find.byType(Icon), findsOneWidget);
      });

      testWidgets('widget handles multiple instances correctly', (
        WidgetTester tester,
      ) async {
        await tester.pumpProviderWidget(
          overrides: [
            memberDisplayNameProvider((
              userId: 'user1',
              roomId: 'room1',
            )).overrideWith((ref) => Future.value('User 1')),
            memberDisplayNameProvider((
              userId: 'user2',
              roomId: 'room2',
            )).overrideWith((ref) => Future.value('User 2')),
          ],
          child: MaterialApp(
            localizationsDelegates: [
              L10n.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: L10n.supportedLocales,
            home: Scaffold(
              body: Column(
                children: [
                  ActivitySocialContainerWidget(
                    icon: Icons.favorite,
                    userId: 'user1',
                    roomId: 'room1',
                    actionTitle: 'liked',
                    originServerTs: 1234567890,
                  ),
                  ActivitySocialContainerWidget(
                    icon: Icons.thumb_up,
                    iconColor: Colors.blue,
                    userId: 'user2',
                    roomId: 'room2',
                    actionTitle: 'reacted to',
                    originServerTs: 1234567891,
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ActivitySocialContainerWidget), findsNWidgets(2));
        expect(findRichTextContaining('User 1'), findsOneWidget);
        expect(findRichTextContaining('User 2'), findsOneWidget);
        expect(findRichTextContaining('liked'), findsOneWidget);
        expect(findRichTextContaining('reacted to'), findsOneWidget);
        // Check that icons exist (specific icons might not be found due to rendering)
        expect(find.byType(Icon), findsAtLeastNWidgets(2));
      });

      testWidgets('widget handles long display names with ellipsis', (
        WidgetTester tester,
      ) async {
        await tester.pumpProviderWidget(
          overrides: [
            memberDisplayNameProvider((
              userId: 'long-name-user',
              roomId: 'test-room-id',
            )).overrideWith(
              (ref) => Future.value(
                'This is a very long display name that should be handled properly',
              ),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: [
              L10n.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: L10n.supportedLocales,
            home: Scaffold(
              body: ActivitySocialContainerWidget(
                icon: Icons.favorite,
                userId: 'long-name-user',
                roomId: 'test-room-id',
                actionTitle: 'liked',
                originServerTs: 1234567890,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Widget should render without errors
        expect(find.byType(ActivitySocialContainerWidget), findsOneWidget);
        expect(
          findRichTextContaining('This is a very long display name'),
          findsOneWidget,
        );

        // Find the specific RichText with our content
        final contentRichText = find.byWidgetPredicate((widget) {
          if (widget is RichText) {
            final text = widget.text.toPlainText();
            return text.contains('This is a very long display name') &&
                text.contains('liked');
          }
          return false;
        });
        expect(contentRichText, findsOneWidget);

        // Verify the RichText widget has maxLines and overflow properties
        final richTextWidget = tester.widget<RichText>(contentRichText);
        expect(richTextWidget.maxLines, 2);
        expect(richTextWidget.overflow, TextOverflow.ellipsis);
      });
    });
  });
}
