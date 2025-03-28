import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/typing_indicator.dart';
import 'package:acter/features/chat_ng/providers/chat_room_messages_provider.dart';
import 'package:acter/features/chat_ng/widgets/chat_messages.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:acter_avatar/acter_avatar.dart';

import '../../../common/mock_data/mock_avatar_info.dart';
import '../../../common/widgets/typing_indicator_test.dart';
import '../../../helpers/test_util.dart';

void main() {
  group('Typing Indicator Mode Tests - Labs integration', () {
    const roomId = 'test-room-id';

    testWidgets(
      'displays name-only typing indicator when Name mode is active',
      (tester) async {
        final overrides = [
          chatTypingEventProvider.overrideWith(
            (ref, arg) => Stream.value(['user1', 'user2']),
          ),

          memberAvatarInfoProvider.overrideWith(
            (ref, info) => MockAvatarInfo(
              uniqueId: info.userId,
              mockDisplayName: info.userId == 'user1' ? 'Alice' : 'Bob',
            ),
          ),
          // override labs feature to activate name-only
          featuresProvider.overrideWith((ref) {
            final notifier = MockFeaturesNotifier(ref);
            notifier.setActive(LabsFeature.typingIndicatorName, true);
            notifier.setActive(LabsFeature.typingIndicatorAvatar, false);
            notifier.setActive(LabsFeature.typingIndicatorNameAndAvatar, false);
            return notifier;
          }),
        ];

        await tester.pumpProviderWidget(
          child: ChatMessages(roomId: roomId),
          overrides: overrides,
        );

        // allow time for stream to emit and UI to update
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(TypingIndicator), findsOneWidget);

        // verify text contains the display names
        expect(find.text('Alice and Bob are typing…'), findsOneWidget);

        // in name-only mode, avatar should not be present
        expect(find.byType(ActerAvatar), findsNothing);
        expect(find.byType(AvatarHandler), findsNothing);

        // animated circles should be present
        expect(find.byType(AnimatedCircles), findsOneWidget);
      },
    );

    testWidgets(
      'displays avatar-only typing indicator when Avatar mode is active',
      (tester) async {
        final overrides = [
          chatTypingEventProvider.overrideWith(
            (ref, arg) => Stream.value(['user1', 'user2']),
          ),

          memberAvatarInfoProvider.overrideWith(
            (ref, info) => MockAvatarInfo(
              uniqueId: info.userId,
              mockDisplayName: info.userId == 'user1' ? 'Alice' : 'Bob',
            ),
          ),
          // override labs feature to activate avatar-only
          featuresProvider.overrideWith((ref) {
            final notifier = MockFeaturesNotifier(ref);
            notifier.setActive(LabsFeature.typingIndicatorName, false);
            notifier.setActive(LabsFeature.typingIndicatorAvatar, true);
            notifier.setActive(LabsFeature.typingIndicatorNameAndAvatar, false);
            return notifier;
          }),
        ];

        await tester.pumpProviderWidget(
          child: ChatMessages(roomId: roomId),
          overrides: overrides,
        );

        // allow time for stream to emit and UI to update
        await tester.pump(const Duration(milliseconds: 500));

        // Verify typing indicator is present
        expect(find.byType(TypingIndicator), findsOneWidget);

        // In avatar-only mode, text should not contain names
        expect(find.textContaining('Alice and Bob are typing…'), findsNothing);

        // Avatar should be present
        expect(find.byType(AvatarHandler), findsOneWidget);
        expect(find.byType(ActerAvatar), findsAtLeastNWidgets(1));

        // Animated circles should be present
        expect(find.byType(AnimatedCircles), findsOneWidget);
      },
    );

    testWidgets(
      'displays combined typing indicator when NameAndAvatar mode is active',
      (tester) async {
        final overrides = [
          chatTypingEventProvider.overrideWith(
            (ref, arg) => Stream.value(['user1', 'user2']),
          ),
          memberAvatarInfoProvider.overrideWith(
            (ref, info) => MockAvatarInfo(
              uniqueId: info.userId,
              mockDisplayName: info.userId == 'user1' ? 'Alice' : 'Bob',
            ),
          ),
          // override labs feature to activate nameAndAvatar
          featuresProvider.overrideWith((ref) {
            final notifier = MockFeaturesNotifier(ref);
            notifier.setActive(LabsFeature.typingIndicatorName, false);
            notifier.setActive(LabsFeature.typingIndicatorAvatar, false);
            notifier.setActive(LabsFeature.typingIndicatorNameAndAvatar, true);
            return notifier;
          }),
        ];

        await tester.pumpProviderWidget(
          child: ChatMessages(roomId: roomId),
          overrides: overrides,
        );

        // allow time for stream to emit and UI to update
        await tester.pump(const Duration(milliseconds: 500));

        // verify typing indicator is present
        expect(find.byType(TypingIndicator), findsOneWidget);

        // In nameAndAvatar mode, both text and avatars should be present
        expect(
          find.textContaining('Alice and Bob are typing…'),
          findsOneWidget,
        );

        // Avatar should be present
        expect(find.byType(AvatarHandler), findsOneWidget);
        expect(find.byType(ActerAvatar), findsAtLeastNWidgets(1));
      },
    );

    testWidgets('defaults to nameAndAvatar mode when no features are active', (
      tester,
    ) async {
      final overrides = [
        chatTypingEventProvider.overrideWith(
          (ref, arg) => Stream.value(['user1', 'user2']),
        ),

        memberAvatarInfoProvider.overrideWith(
          (ref, info) => MockAvatarInfo(
            uniqueId: info.userId,
            mockDisplayName: info.userId == 'user1' ? 'Alice' : 'Bob',
          ),
        ),

        featuresProvider.overrideWith((ref) {
          final notifier = MockFeaturesNotifier(ref);
          notifier.setActive(LabsFeature.typingIndicatorName, false);
          notifier.setActive(LabsFeature.typingIndicatorAvatar, false);
          notifier.setActive(LabsFeature.typingIndicatorNameAndAvatar, false);
          return notifier;
        }),
      ];

      await tester.pumpProviderWidget(
        child: ChatMessages(roomId: roomId),
        overrides: overrides,
      );

      // allow time for stream to emit and UI to update
      await tester.pump(const Duration(milliseconds: 500));

      // verify typing indicator is present
      expect(find.byType(TypingIndicator), findsOneWidget);

      // should default to nameAndAvatar mode
      expect(find.textContaining('Alice and Bob are typing…'), findsOneWidget);

      // avatar should be present
      expect(find.byType(AvatarHandler), findsOneWidget);
      expect(find.byType(ActerAvatar), findsAtLeastNWidgets(1));
    });

    testWidgets('mode changes dynamically when lab features are updated', (
      tester,
    ) async {
      late MockFeaturesNotifier notifier;

      final overrides = [
        chatTypingEventProvider.overrideWith(
          (ref, arg) => Stream.value(['user1']),
        ),
        memberAvatarInfoProvider.overrideWith(
          (ref, info) =>
              MockAvatarInfo(uniqueId: info.userId, mockDisplayName: 'Alice'),
        ),
        // override labs feature provider - start with nameAndAvatar mode
        featuresProvider.overrideWith((ref) {
          notifier = MockFeaturesNotifier(ref);
          notifier.setActive(LabsFeature.typingIndicatorName, false);
          notifier.setActive(LabsFeature.typingIndicatorAvatar, false);
          notifier.setActive(LabsFeature.typingIndicatorNameAndAvatar, true);
          return notifier;
        }),
      ];

      await tester.pumpProviderWidget(
        child: ChatMessages(roomId: roomId),
        overrides: overrides,
      );
      await tester.pump(const Duration(milliseconds: 500));

      // initial mode should show both text and avatar
      expect(find.textContaining('Alice'), findsOneWidget);
      expect(find.byType(AvatarHandler), findsOneWidget);

      // change to name-only mode
      await notifier.setActive(LabsFeature.typingIndicatorName, true);
      await notifier.setActive(LabsFeature.typingIndicatorNameAndAvatar, false);
      await tester.pump(const Duration(milliseconds: 500));

      // should now show text but no avatar
      expect(find.textContaining('Alice is typing…'), findsOneWidget);
      expect(find.byType(AvatarHandler), findsNothing);

      // change to avatar-only mode
      await notifier.setActive(LabsFeature.typingIndicatorName, false);
      await notifier.setActive(LabsFeature.typingIndicatorAvatar, true);
      await tester.pump(const Duration(milliseconds: 500));

      // should now show avatar but no text
      expect(find.textContaining('Alice is typing…'), findsNothing);
      expect(find.byType(AvatarHandler), findsOneWidget);
    });
  });
}
