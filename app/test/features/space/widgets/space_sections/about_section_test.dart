
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/space/providers/topic_provider.dart';
import 'package:acter/features/space/widgets/space_sections/about_section.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/test_util.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class MockSpace extends Mock implements Space {
  final String id;
  final String? topicText;
  final bool canSetTopic;
  final Member? membership;

  MockSpace({
    this.id = 'test-space-id',
    this.topicText,
    this.canSetTopic = false,
    this.membership,
  });

  @override
  String getRoomIdStr() => id;

  @override
  String? topic() => topicText;

  @override
  Future<Member> getMyMembership() async => membership!;
}

class MockMembership extends Mock implements Member {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeContext());
    registerFallbackValue(FakeWidgetRef());
  });

  group('AboutSection', () {
    const testSpaceId = 'test-space-id';
    const testTopic = 'This is a test space topic';

    group('Space Description', () {
      testWidgets('renders topic when available', (tester) async {
        await tester.pumpProviderWidget(
          overrides: [
            spaceProvider.overrideWith((ref, _) => Future.value(MockSpace())),
            roomMembershipProvider.overrideWith(
              (ref, _) => Future.value(MockMembership()),
            ),
            topicProvider.overrideWith((ref, _) => Future.value(testTopic)),
          ],
          child: const AboutSection(spaceId: testSpaceId),
        );

        await tester.pump();
        expect(find.text(testTopic), findsOneWidget);
      });

      testWidgets('renders no topic found message when topic is null', (
        tester,
      ) async {
        await tester.pumpProviderWidget(
          overrides: [
            spaceProvider.overrideWith((ref, _) => Future.value(MockSpace())),
            topicProvider.overrideWith((ref, _) => Future.value(null)),
            roomMembershipProvider.overrideWith(
              (ref, _) => Future.value(MockMembership()),
            ),
          ],
          child: const AboutSection(spaceId: testSpaceId),
        );

        await tester.pump();
        expect(find.text('No topic found'), findsOneWidget);
      });

      testWidgets('makes topic editable when user has permission', (
        tester,
      ) async {
        final mockMembership = MockMembership();
        when(() => mockMembership.canString('CanSetTopic')).thenReturn(true);
        await tester.pumpProviderWidget(
          overrides: [
            spaceProvider.overrideWith((ref, _) => Future.value(MockSpace())),
            topicProvider.overrideWith((ref, _) => Future.value(testTopic)),
            roomMembershipProvider.overrideWith(
              (ref, _) => Future.value(mockMembership),
            ),
          ],
          child: const AboutSection(spaceId: testSpaceId),
        );

        await tester.pump();
        expect(find.byType(GestureDetector), findsOneWidget);
        expect(find.byType(SelectionArea), findsOneWidget);
      });

      testWidgets('topic is not editable without permission', (tester) async {
        final mockMembership = MockMembership();
        when(() => mockMembership.canString('CanSetTopic')).thenReturn(false);
        await tester.pumpProviderWidget(
          overrides: [
            spaceProvider.overrideWith((ref, _) => Future.value(MockSpace())),
            topicProvider.overrideWith((ref, _) => Future.value(testTopic)),
            roomMembershipProvider.overrideWith(
              (ref, _) => Future.value(mockMembership),
            ),
          ],
          child: const AboutSection(spaceId: testSpaceId),
        );

        await tester.pump();
        expect(find.byType(GestureDetector), findsNothing);
        expect(find.byType(SelectionArea), findsOneWidget);
      });
    });

    group('Acter Space Upgrade', () {
      testWidgets('shows upgrade button for non-acter space with permissions', (
        tester,
      ) async {
        final mockMembership = MockMembership();
        when(
          () => mockMembership.canString('CanUpgradeToActerSpace'),
        ).thenReturn(true);
        await tester.pumpProviderWidget(
          overrides: [
            spaceProvider.overrideWith((ref, _) => Future.value(MockSpace())),
            topicProvider.overrideWith((ref, _) => Future.value(testTopic)),
            isActerSpace.overrideWith((ref, _) => Future.value(false)),
            roomMembershipProvider.overrideWith(
              (ref, _) => Future.value(mockMembership),
            ),
          ],
          child: const AboutSection(spaceId: testSpaceId),
        );

        await tester.pump();
        expect(find.text('Upgrade to Acter Space'), findsOneWidget);
        expect(find.byIcon(Atlas.up_arrow), findsOneWidget);
      });

      testWidgets('hides upgrade button for acter space', (tester) async {
        final mockMembership = MockMembership();
        when(
          () => mockMembership.canString('CanUpgradeToActerSpace'),
        ).thenReturn(false);
        await tester.pumpProviderWidget(
          overrides: [
            spaceProvider.overrideWith((ref, _) => Future.value(MockSpace())),
            topicProvider.overrideWith((ref, _) => Future.value(testTopic)),
            isActerSpace.overrideWith((ref, _) => Future.value(true)),
            roomMembershipProvider.overrideWith(
              (ref, _) => Future.value(mockMembership),
            ),
          ],
          child: const AboutSection(spaceId: testSpaceId),
        );

        await tester.pump();
        expect(find.text('Upgrade to Acter Space'), findsNothing);
        expect(find.byIcon(Atlas.up_arrow), findsNothing);
      });

      testWidgets('hides upgrade button without permission', (tester) async {
        await tester.pumpProviderWidget(
          overrides: [
            spaceProvider.overrideWith((ref, _) => Future.value(MockSpace())),
            topicProvider.overrideWith((ref, _) => Future.value(testTopic)),
            isActerSpace.overrideWith((ref, _) => Future.value(false)),
          ],
          child: const AboutSection(spaceId: testSpaceId),
        );

        await tester.pump();
        expect(find.text('Upgrade to Acter Space'), findsNothing);
        expect(find.byIcon(Atlas.up_arrow), findsNothing);
      });

      testWidgets('calls setActerSpaceStates when upgrade button is tapped', (
        tester,
      ) async {
        final mockMembership = MockMembership();
        final mockSpace = MockSpace(membership: mockMembership);
        when(
          () => mockSpace.setActerSpaceStates(),
        ).thenAnswer((_) async => Future<bool>.value(true));
        when(
          () => mockMembership.canString('CanUpgradeToActerSpace'),
        ).thenReturn(true);
        when(() => mockMembership.canString('CanSetTopic')).thenReturn(false);

        await tester.pumpProviderWidget(
          overrides: [
            spaceProvider.overrideWith((ref, _) => Future.value(mockSpace)),
            topicProvider.overrideWith((ref, _) => Future.value(testTopic)),
            isActerSpace.overrideWith((ref, _) => Future.value(false)),
            roomMembershipProvider.overrideWith(
              (ref, _) => Future.value(mockMembership),
            ),
          ],
          child: const AboutSection(spaceId: testSpaceId),
        );

        await tester.pump();

        debugDumpApp();

        // Find and tap the upgrade button
        // doesn't find outline button as its using the .icon variant
        final upgradeButton = find.text('Upgrade to Acter Space');
        expect(upgradeButton, findsOneWidget);
        await tester.tap(upgradeButton);
        await tester.pump();

        // Verify that setActerSpaceStates was called
        verify(() => mockSpace.setActerSpaceStates()).called(1);
        expect(EasyLoading.isShow, isTrue);
      });

      testWidgets('shows error toast when upgrade fails', (tester) async {
        final mockSpace = MockSpace();
        when(
          () => mockSpace.setActerSpaceStates(),
        ).thenThrow(Exception('Upgrade failed'));
        final mockMembership = MockMembership();
        when(
          () => mockMembership.canString('CanUpgradeToActerSpace'),
        ).thenReturn(true);

        await tester.pumpProviderWidget(
          overrides: [
            spaceProvider.overrideWith((ref, _) => Future.value(mockSpace)),
            topicProvider.overrideWith((ref, _) => Future.value(testTopic)),
            isActerSpace.overrideWith((ref, _) => Future.value(false)),
            roomMembershipProvider.overrideWith(
              (ref, _) => Future.value(mockMembership),
            ),
          ],
          child: const AboutSection(spaceId: testSpaceId),
        );

        await tester.pump();

        // doesn't find outline button as its using the .icon variant
        final upgradeButton = find.text('Upgrade to Acter Space');
        await tester.tap(upgradeButton);
        await tester.pump();

        verify(() => mockSpace.setActerSpaceStates()).called(1);
        expect(EasyLoading.isShow, isTrue);
      });
    });
  });
}

// Fake implementations for use with registerFallbackValue
class FakeContext extends Fake implements BuildContext {}

class FakeWidgetRef extends Fake implements WidgetRef {}
