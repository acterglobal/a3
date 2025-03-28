import 'package:acter/common/themes/acter_theme.dart';
import 'package:acter/common/widgets/typing_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../helpers/test_util.dart';
import '../mock_data/mock_avatar_info.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter/features/labs/feature_flagger.dart';
import 'package:acter/features/labs/providers/notifiers/labs_features.dart';

class MockFeaturesNotifier extends SharedPrefFeaturesNotifier {
  MockFeaturesNotifier(Ref ref) : super('test_key', ref);

  @override
  Future<void> setActive(LabsFeature f, bool active) async {
    final currentFlags = List<FeatureFlag<LabsFeature>>.from(state.flags);
    final existingIndex = currentFlags.indexWhere((flag) => flag.feature == f);

    if (existingIndex >= 0) {
      currentFlags[existingIndex] = FeatureFlag<LabsFeature>(
        feature: f,
        active: active,
      );
    } else {
      currentFlags.add(FeatureFlag<LabsFeature>(feature: f, active: active));
    }

    state = Features(flags: currentFlags, defaultOn: LabsFeature.defaults);
  }
}

void main() {
  group('Typing Indicator Widget', () {
    testWidgets('should show name only mode', (tester) async {
      final testUser = AvatarInfo(
        uniqueId: 'test_user',
        displayName: 'Test User',
      );

      await tester.pumpProviderWidget(
        overrides: [
          featuresProvider.overrideWith((ref) {
            final notifier = MockFeaturesNotifier(ref);
            notifier.setActive(LabsFeature.typingIndicatorName, true);
            return notifier;
          }),
        ],
        child: TypingIndicator(
          options: TypingIndicatorOptions(typingUsers: [testUser]),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      // verify name is shown
      expect(find.text('Test User is typing…'), findsOneWidget);
      // verify avatar is not shown
      expect(find.byType(ActerAvatar), findsNothing);
    });

    testWidgets('should show avatar only mode', (tester) async {
      final testUser = AvatarInfo(
        uniqueId: 'test_user',
        displayName: 'Test User',
      );

      await tester.pumpProviderWidget(
        overrides: [
          featuresProvider.overrideWith((ref) {
            final notifier = MockFeaturesNotifier(ref);
            notifier.setActive(LabsFeature.typingIndicatorAvatar, true);
            return notifier;
          }),
        ],
        child: TypingIndicator(
          options: TypingIndicatorOptions(typingUsers: [testUser]),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      // verify name is not shown
      expect(find.text('Test User is typing…'), findsNothing);
      // verify avatar is shown
      expect(find.byType(ActerAvatar), findsOneWidget);
    });

    testWidgets('should show name and avatar mode', (tester) async {
      final testUser = AvatarInfo(
        uniqueId: 'test_user',
        displayName: 'Test User',
      );

      await tester.pumpProviderWidget(
        overrides: [
          featuresProvider.overrideWith((ref) {
            final notifier = MockFeaturesNotifier(ref);
            notifier.setActive(LabsFeature.typingIndicatorNameAndAvatar, true);
            return notifier;
          }),
        ],
        child: TypingIndicator(
          options: TypingIndicatorOptions(typingUsers: [testUser]),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      // verify both name and avatar are shown
      expect(find.text('Test User is typing…'), findsOneWidget);
      expect(find.byType(ActerAvatar), findsOneWidget);
    });

    testWidgets('should handle multiple users in mode', (tester) async {
      final testUser = AvatarInfo(
        uniqueId: 'test_user',
        displayName: 'Test User',
      );
      final testUser2 = AvatarInfo(
        uniqueId: 'test_user2',
        displayName: 'Test User 2',
      );

      await tester.pumpProviderWidget(
        overrides: [
          featuresProvider.overrideWith((ref) {
            final notifier = MockFeaturesNotifier(ref);
            notifier.setActive(LabsFeature.typingIndicatorNameAndAvatar, true);
            return notifier;
          }),
        ],
        child: TypingIndicator(
          options: TypingIndicatorOptions(typingUsers: [testUser, testUser2]),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      // verify the text contains the display names
      expect(
        find.text('Test User and Test User 2 are typing…'),
        findsOneWidget,
      );
      expect(find.byType(ActerAvatar), findsNWidgets(2));
    });
  });

  group('Typing Indicator Widget Unit Tests', () {
    testWidgets('should display single user in name mode correctly', (
      tester,
    ) async {
      final options = TypingIndicatorOptions(
        typingUsers: [
          MockAvatarInfo(uniqueId: 'user1', mockDisplayName: 'Alice'),
        ],
        mode: TypingIndicatorMode.name,
      );

      await tester.pumpProviderWidget(child: TypingIndicator(options: options));

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(Text), findsOneWidget);
      // verify the text contains the display name
      expect(find.textContaining('Alice'), findsOneWidget);
    });

    testWidgets('should display two users in name mode correctly', (
      tester,
    ) async {
      final options = TypingIndicatorOptions(
        typingUsers: [
          MockAvatarInfo(uniqueId: 'user1', mockDisplayName: 'Alice'),
          MockAvatarInfo(uniqueId: 'user2', mockDisplayName: 'Bob'),
        ],
        mode: TypingIndicatorMode.name,
      );

      await tester.pumpProviderWidget(child: TypingIndicator(options: options));

      await tester.pump(const Duration(milliseconds: 300));

      // verify the text contains the display names
      expect(find.textContaining('Alice'), findsOneWidget);
      expect(find.textContaining('Bob'), findsOneWidget);
    });

    testWidgets('should display multiple users in name mode correctly', (
      tester,
    ) async {
      final options = TypingIndicatorOptions(
        typingUsers: [
          MockAvatarInfo(uniqueId: 'user1', mockDisplayName: 'Alice'),
          MockAvatarInfo(uniqueId: 'user2', mockDisplayName: 'Bob'),
          MockAvatarInfo(uniqueId: 'user3', mockDisplayName: 'Charlie'),
        ],
        mode: TypingIndicatorMode.name,
      );

      await tester.pumpProviderWidget(child: TypingIndicator(options: options));

      await tester.pump(const Duration(milliseconds: 300));

      // verify the text contains the display name
      expect(find.textContaining('Alice'), findsOneWidget);
      // verify the rest count of users
      expect(find.textContaining('2'), findsOneWidget);
    });

    testWidgets('should display single user in avatar mode correctly', (
      tester,
    ) async {
      final options = TypingIndicatorOptions(
        typingUsers: [
          MockAvatarInfo(uniqueId: 'user1', mockDisplayName: 'Alice'),
        ],
        mode: TypingIndicatorMode.avatar,
      );

      await tester.pumpProviderWidget(child: TypingIndicator(options: options));

      await tester.pump(const Duration(milliseconds: 300));

      // verify avatar is shown
      expect(find.byType(AvatarHandler), findsOneWidget);
      expect(find.byType(AnimatedCircles), findsOneWidget);
      expect(
        find.text('Alice'),
        findsNothing,
      ); // name shouldn't be shown in avatar mode
    });

    testWidgets('should display nameAndAvatar mode correctly', (tester) async {
      final options = TypingIndicatorOptions(
        typingUsers: [
          MockAvatarInfo(uniqueId: 'user1', mockDisplayName: 'Alice'),
        ],
        mode: TypingIndicatorMode.nameAndAvatar,
      );

      await tester.pumpProviderWidget(child: TypingIndicator(options: options));

      await tester.pump(const Duration(milliseconds: 300));

      // should show both avatar and text
      expect(find.byType(AvatarHandler), findsOneWidget);
      expect(find.textContaining('Alice'), findsOneWidget);
    });

    group('Avatar Handler and LTR-RTL support unit tests', () {
      testWidgets('should handle empty users list', (tester) async {
        await tester.pumpProviderWidget(
          child: AvatarHandler(users: const [], isRtl: false),
        );

        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(SizedBox), findsOneWidget);
        expect(find.byType(TypingAvatar), findsNothing);
      });

      testWidgets('should handle single user correctly in LTR', (tester) async {
        await tester.pumpProviderWidget(
          child: AvatarHandler(
            users: [
              MockAvatarInfo(uniqueId: 'user1', mockDisplayName: 'Alice'),
            ],
            isRtl: false,
          ),
        );

        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(TypingAvatar), findsOneWidget);
        expect(find.byType(Align), findsOneWidget);

        final align = tester.widget<Align>(find.byType(Align));
        expect(align.alignment, equals(Alignment.centerLeft));
      });

      testWidgets('should handle single user correctly in RTL', (tester) async {
        await tester.pumpProviderWidget(
          child: AvatarHandler(
            users: [MockAvatarInfo(uniqueId: 'user1', mockDisplayName: 'آدم')],
            isRtl: true,
          ),
        );

        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(TypingAvatar), findsOneWidget);
        expect(find.byType(Align), findsOneWidget);

        final align = tester.widget<Align>(find.byType(Align));
        expect(align.alignment, equals(Alignment.centerRight));
      });

      testWidgets('should handle two users correctly in LTR', (tester) async {
        await tester.pumpProviderWidget(
          child: AvatarHandler(
            users: [
              MockAvatarInfo(uniqueId: 'user1', mockDisplayName: 'Alice'),
              MockAvatarInfo(uniqueId: 'user2', mockDisplayName: 'Bob'),
            ],
            isRtl: false,
          ),
        );

        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(TypingAvatar), findsNWidgets(2));
        expect(find.byType(Stack), findsNWidgets(2));
        expect(find.byType(Positioned), findsOneWidget);

        final positioned = tester.widget<Positioned>(find.byType(Positioned));
        expect(positioned.left, equals(16));
        expect(positioned.right, isNull);
      });

      testWidgets('should handle two users correctly in RTL', (tester) async {
        await tester.pumpProviderWidget(
          child: AvatarHandler(
            users: [
              MockAvatarInfo(uniqueId: 'user1', mockDisplayName: 'آدم'),
              MockAvatarInfo(uniqueId: 'user2', mockDisplayName: 'باسم'),
            ],
            isRtl: true,
          ),
        );

        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(TypingAvatar), findsNWidgets(2));
        expect(find.byType(Stack), findsNWidgets(2));
        expect(find.byType(Positioned), findsOneWidget);

        final positioned = tester.widget<Positioned>(find.byType(Positioned));
        expect(positioned.left, isNull);
        expect(positioned.right, equals(16));
      });

      testWidgets('should handle three or more users correctly in LTR', (
        tester,
      ) async {
        await tester.pumpProviderWidget(
          child: AvatarHandler(
            users: [
              MockAvatarInfo(uniqueId: 'user1', mockDisplayName: 'Alice'),
              MockAvatarInfo(uniqueId: 'user2', mockDisplayName: 'Bob'),
              MockAvatarInfo(uniqueId: 'user3', mockDisplayName: 'Charlie'),
            ],
            isRtl: false,
          ),
        );

        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(TypingAvatar), findsNWidgets(2));
        expect(find.byType(CircleAvatar), findsOneWidget);
        expect(find.text('1'), findsOneWidget);

        final positionedWidgets = tester.widgetList<Positioned>(
          find.byType(Positioned),
        );
        final List<Positioned> positioned = positionedWidgets.toList();

        expect(positioned[0].left, equals(16));
        expect(positioned[0].right, isNull);

        expect(positioned[1].left, equals(32));
        expect(positioned[1].right, isNull);
      });

      testWidgets('should handle three or more users correctly in RTL', (
        tester,
      ) async {
        await tester.pumpProviderWidget(
          child: AvatarHandler(
            users: [
              MockAvatarInfo(uniqueId: 'user1', mockDisplayName: 'آدم'),
              MockAvatarInfo(uniqueId: 'user2', mockDisplayName: 'باسم'),
              MockAvatarInfo(uniqueId: 'user3', mockDisplayName: 'جمال'),
              MockAvatarInfo(uniqueId: 'user4', mockDisplayName: 'داوود'),
            ],
            isRtl: true,
          ),
        );

        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(TypingAvatar), findsNWidgets(2));
        expect(find.byType(CircleAvatar), findsOneWidget);
        expect(find.text('2'), findsOneWidget);

        final positionedWidgets = tester.widgetList<Positioned>(
          find.byType(Positioned),
        );
        final List<Positioned> positioned = positionedWidgets.toList();

        expect(positioned[0].left, isNull);
        expect(positioned[0].right, equals(16));

        expect(positioned[1].left, isNull);
        expect(positioned[1].right, equals(32));
      });
    });

    group('Animated Circles Unit Tests', () {
      final theme = TypingIndicatorTheme(
        animatedCirclesColor: Colors.blue,
        multipleUserTextStyle: const TextStyle(fontSize: 12),
        countAvatarColor: Colors.grey,
        countTextColor: Colors.white,
      );

      testWidgets('should render three circles', (tester) async {
        await tester.pumpProviderWidget(child: AnimatedCircles(theme: theme));

        await tester.pump(const Duration(milliseconds: 300));

        // verify three animated circles
        final row = tester.widget<Row>(find.byType(Row));
        expect(row.children.length, equals(3));
      });
    });
  });
}
