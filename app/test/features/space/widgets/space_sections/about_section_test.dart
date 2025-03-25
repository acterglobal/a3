import 'dart:async';

import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/space/widgets/space_sections/about_section.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../helpers/test_util.dart';

class MockSpace extends Mock implements Space {
  final String id;
  final String? topicText;
  final bool canSetTopic;

  MockSpace({
    this.id = 'test-space-id',
    this.topicText,
    this.canSetTopic = false,
  });

  @override
  String getRoomIdStr() => id;

  @override
  String? topic() => topicText;
}

class MockMembership extends Mock implements Member {
  final bool canSetTopic;

  MockMembership({this.canSetTopic = false});

  @override
  bool canString(String permission) {
    if (permission == 'CanSetTopic') {
      return canSetTopic;
    }
    return false;
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeContext());
    registerFallbackValue(FakeWidgetRef());
  });

  group('AboutSection', () {
    const testSpaceId = 'test-space-id';
    const testTopic = 'This is a test space topic';

    testWidgets('renders loading state correctly', (tester) async {
      final completer = Completer<Space>();
      final mockSpace = MockSpace(topicText: testTopic);
      await tester.pumpProviderWidget(
        overrides: [spaceProvider.overrideWith((ref, _) => completer.future)],
        child: const AboutSection(spaceId: testSpaceId),
      );

      expect(find.text('Loading'), findsOneWidget);
      completer.complete(mockSpace);
      await tester.pump();
      expect(find.text(testTopic), findsOneWidget);
    });

    testWidgets('renders space topic when available', (tester) async {
      final mockSpace = MockSpace(topicText: testTopic);

      await tester.pumpProviderWidget(
        overrides: [
          spaceProvider.overrideWith((ref, _) => Future.value(mockSpace)),
        ],
        child: const AboutSection(spaceId: testSpaceId),
      );

      await tester.pump();
      expect(find.text(testTopic), findsOneWidget);
    });

    testWidgets('renders no topic found message when topic is null', (
      tester,
    ) async {
      final mockSpace = MockSpace(topicText: null);

      await tester.pumpProviderWidget(
        overrides: [
          spaceProvider.overrideWith((ref, _) => Future.value(mockSpace)),
        ],
        child: const AboutSection(spaceId: testSpaceId),
      );

      await tester.pump();
      expect(find.text('No topic found'), findsOneWidget);
    });

    testWidgets('renders action to convert non acter space', (tester) async {
      final mockSpace = MockSpace(topicText: null);

      await tester.pumpProviderWidget(
        overrides: [
          spaceProvider.overrideWith((ref, _) => Future.value(mockSpace)),
        ],
        child: const AboutSection(spaceId: testSpaceId),
      );

      await tester.pump();
      expect(find.text('No topic found'), findsOneWidget);
    });

    testWidgets('renders error message when spaceProvider fails', (
      tester,
    ) async {
      const errorMessage = 'Test error';

      await tester.pumpProviderWidget(
        overrides: [
          spaceProvider.overrideWith(
            (ref, _) => Future<Space>.error(errorMessage),
          ),
        ],
        child: const AboutSection(spaceId: testSpaceId),
      );

      await tester.pump();
      expect(find.textContaining(errorMessage), findsOneWidget);
    });

    testWidgets('shows upgrade button for non-acter space with permissions', (
      tester,
    ) async {
      final mockSpace = MockSpace(topicText: testTopic, canSetTopic: true);
      final mockMembership = MockMembership(canSetTopic: true);
      when(
        () => mockSpace.getMyMembership(),
      ).thenAnswer((_) async => mockMembership);

      await tester.pumpProviderWidget(
        overrides: [
          spaceProvider.overrideWith((ref, _) => Future.value(mockSpace)),
          isActerSpace.overrideWith((ref, _) => Future.value(false)),
          roomPermissionProvider.overrideWith((ref, arg) => Future.value(true)),
        ],
        child: const AboutSection(spaceId: testSpaceId),
      );

      await tester.pump();
      expect(find.text('Upgrade to Acter Space'), findsOneWidget);
      expect(find.byIcon(Atlas.up_arrow), findsOneWidget);
    });

    testWidgets('hides upgrade button for acter space', (tester) async {
      final mockSpace = MockSpace(topicText: testTopic, canSetTopic: true);
      final mockMembership = MockMembership(canSetTopic: true);
      when(
        () => mockSpace.getMyMembership(),
      ).thenAnswer((_) async => mockMembership);

      await tester.pumpProviderWidget(
        overrides: [
          spaceProvider.overrideWith((ref, _) => Future.value(mockSpace)),
          isActerSpace.overrideWith((ref, _) => Future.value(true)),
          roomPermissionProvider.overrideWith((ref, arg) => Future.value(true)),
        ],
        child: const AboutSection(spaceId: testSpaceId),
      );

      await tester.pump();
      expect(find.text('Upgrade to Acter Space'), findsNothing);
    });

    testWidgets('hides upgrade button when user lacks permission', (
      tester,
    ) async {
      final mockSpace = MockSpace(topicText: testTopic, canSetTopic: false);
      final mockMembership = MockMembership(canSetTopic: false);
      when(
        () => mockSpace.getMyMembership(),
      ).thenAnswer((_) async => mockMembership);

      await tester.pumpProviderWidget(
        overrides: [
          spaceProvider.overrideWith((ref, _) => Future.value(mockSpace)),
          isActerSpace.overrideWith((ref, _) => Future.value(false)),
          roomPermissionProvider.overrideWith(
            (ref, arg) => Future.value(false),
          ),
        ],
        child: const AboutSection(spaceId: testSpaceId),
      );

      await tester.pump();
      expect(find.text('Upgrade to Acter Space'), findsNothing);
    });
  });
}

// Fake implementations for use with registerFallbackValue
class FakeContext extends Fake implements BuildContext {}

class FakeWidgetRef extends Fake implements WidgetRef {}
