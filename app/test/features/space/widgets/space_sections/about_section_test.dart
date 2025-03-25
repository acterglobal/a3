import 'dart:async';

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

    group('Space Description', () {
      testWidgets('renders topic when available', (tester) async {
        await tester.pumpProviderWidget(
          overrides: [
            spaceProvider.overrideWith((ref, _) => Future.value(MockSpace())),
            topicProvider.overrideWith((ref, _) => Future.value(testTopic)),
            roomPermissionProvider.overrideWith(
              (ref, _) => Future.value(false),
            ),
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
            roomPermissionProvider.overrideWith(
              (ref, _) => Future.value(false),
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
        await tester.pumpProviderWidget(
          overrides: [
            spaceProvider.overrideWith((ref, _) => Future.value(MockSpace())),
            topicProvider.overrideWith((ref, _) => Future.value(testTopic)),
            roomPermissionProvider.overrideWith(
              (ref, p) => Future.value(p.permission == 'CanSetTopic'),
            ),
          ],
          child: const AboutSection(spaceId: testSpaceId),
        );

        await tester.pump();
        expect(find.byType(GestureDetector), findsOneWidget);
        expect(find.byType(SelectionArea), findsOneWidget);
      });

      testWidgets('topic is not editable without permission', (tester) async {
        await tester.pumpProviderWidget(
          overrides: [
            spaceProvider.overrideWith((ref, _) => Future.value(MockSpace())),
            topicProvider.overrideWith((ref, _) => Future.value(testTopic)),
            roomPermissionProvider.overrideWith(
              (ref, _) => Future.value(false),
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
        await tester.pumpProviderWidget(
          overrides: [
            spaceProvider.overrideWith((ref, _) => Future.value(MockSpace())),
            topicProvider.overrideWith((ref, _) => Future.value(testTopic)),
            isActerSpace.overrideWith((ref, _) => Future.value(false)),
            roomPermissionProvider.overrideWith(
              (ref, p) =>
                  Future.value(p.permission == 'CanUpgradeToActerSpace'),
            ),
          ],
          child: const AboutSection(spaceId: testSpaceId),
        );

        await tester.pump();
        expect(find.text('Upgrade to Acter Space'), findsOneWidget);
        expect(find.byIcon(Atlas.up_arrow), findsOneWidget);
      });

      testWidgets('hides upgrade button for acter space', (tester) async {
        await tester.pumpProviderWidget(
          overrides: [
            spaceProvider.overrideWith((ref, _) => Future.value(MockSpace())),
            topicProvider.overrideWith((ref, _) => Future.value(testTopic)),
            isActerSpace.overrideWith((ref, _) => Future.value(true)),
            roomPermissionProvider.overrideWith(
              (ref, p) =>
                  Future.value(p.permission == 'CanUpgradeToActerSpace'),
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
            roomPermissionProvider.overrideWith(
              (ref, _) => Future.value(false),
            ),
          ],
          child: const AboutSection(spaceId: testSpaceId),
        );

        await tester.pump();
        expect(find.text('Upgrade to Acter Space'), findsNothing);
        expect(find.byIcon(Atlas.up_arrow), findsNothing);
      });
    });
  });
}

// Fake implementations for use with registerFallbackValue
class FakeContext extends Fake implements BuildContext {}

class FakeWidgetRef extends Fake implements WidgetRef {}
