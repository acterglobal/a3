import 'dart:async';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/space/widgets/space_sections/about_section.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
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
  });
}

// Fake implementations for use with registerFallbackValue
class FakeContext extends Fake implements BuildContext {}

class FakeWidgetRef extends Fake implements WidgetRef {}
