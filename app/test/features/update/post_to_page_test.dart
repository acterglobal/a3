import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/news/model/news_post_state.dart';
import 'package:acter/features/news/pages/add_news/add_news_post_to_page.dart';
import 'package:acter/features/news/providers/news_post_editor_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_util.dart';

// Mock classes
class MockNewsPostState extends Mock implements NewsPostState {
  @override
  String? newsPostSpaceId;
}

class MockNewsStateNotifier extends StateNotifier<NewsPostState>
    with Mock
    implements NewsStateNotifier {
  MockNewsStateNotifier() : super(NewsPostState());
}

class MockMember extends Mock implements Member {}

void main() {
  late MockNewsPostState mockNewsPostState;
  late MockNewsStateNotifier mockNewsStateNotifier;
  late MockMember mockMember;

  setUp(() {
    mockNewsPostState = MockNewsPostState();
    mockNewsStateNotifier = MockNewsStateNotifier();
    mockMember = MockMember();

    mockNewsPostState.newsPostSpaceId = null;
    when(() => mockMember.canString('CanPostNews')).thenReturn(false);
    when(() => mockMember.canString('CanPostStories')).thenReturn(false);
  });

  Future<void> createWidgetUnderTest(WidgetTester tester) {
    return tester.pumpProviderWidget(
      child: AddNewsPostToPage(),
      overrides: [
        newsStateProvider.overrideWith((ref) => mockNewsStateNotifier),
        roomMembershipProvider.overrideWith((a, b) => mockMember),
      ],
    );
  }

  group('AddNewsPostToPage', () {
    testWidgets('shows select space button when no space is selected',
        (tester) async {
      mockNewsPostState.newsPostSpaceId = null;
      mockNewsStateNotifier.state = mockNewsPostState;

      await createWidgetUnderTest(tester);
      await tester.pumpAndSettle();

      expect(find.text('Select Space'), findsOneWidget);
    });

    testWidgets('shows space info when space is selected', (tester) async {
      mockNewsPostState.newsPostSpaceId = 'test-space-id';
      mockNewsStateNotifier.state = mockNewsPostState;

      await createWidgetUnderTest(tester);
      await tester.pumpAndSettle();

      expect(find.text('Select Space'), findsNothing);
    });

    testWidgets('shows both options disabled if member has no permission',
        (tester) async {
      mockNewsPostState.newsPostSpaceId = 'test-space-id';
      mockNewsStateNotifier.state = mockNewsPostState;
      when(() => mockMember.canString('CanPostNews')).thenReturn(false);
      when(() => mockMember.canString('CanPostStories')).thenReturn(false);

      await createWidgetUnderTest(tester);
      await tester.pumpAndSettle();

      final storyText = tester.widget<Text>(find.text('Story'));
      final boostText = tester.widget<Text>(find.text('Boost'));
      expect(
        storyText.style?.color,
        equals(Theme.of(tester.element(find.text('Story'))).disabledColor),
      );
      expect(
        boostText.style?.color,
        equals(Theme.of(tester.element(find.text('Boost'))).disabledColor),
      );
    });

    testWidgets('shows both options enabled if member has permission',
        (tester) async {
      mockNewsPostState.newsPostSpaceId = 'test-space-id';
      mockNewsStateNotifier.state = mockNewsPostState;
      when(() => mockMember.canString('CanPostNews')).thenReturn(true);
      when(() => mockMember.canString('CanPostStories')).thenReturn(true);

      await createWidgetUnderTest(tester);
      await tester.pumpAndSettle();

      final storyText = tester.widget<Text>(find.text('Story'));
      final boostText = tester.widget<Text>(find.text('Boost'));
      expect(
        storyText.style?.color,
        equals(
          Theme.of(tester.element(find.text('Story'))).colorScheme.onSurface,
        ),
      );
      expect(
        boostText.style?.color,
        equals(
          Theme.of(tester.element(find.text('Boost'))).colorScheme.onSurface,
        ),
      );
    });

    testWidgets(
        'shows story option enabled and news option disabled if member has permission',
        (tester) async {
      mockNewsPostState.newsPostSpaceId = 'test-space-id';
      mockNewsStateNotifier.state = mockNewsPostState;
      when(() => mockMember.canString('CanPostNews')).thenReturn(false);
      when(() => mockMember.canString('CanPostStories')).thenReturn(true);

      await createWidgetUnderTest(tester);
      await tester.pumpAndSettle();

      final storyText = tester.widget<Text>(find.text('Story'));
      final boostText = tester.widget<Text>(find.text('Boost'));
      expect(
        storyText.style?.color,
        equals(
          Theme.of(tester.element(find.text('Story'))).colorScheme.onSurface,
        ),
      );
      expect(
        boostText.style?.color,
        equals(
          Theme.of(tester.element(find.text('Boost'))).disabledColor,
        ),
      );
    });
    testWidgets(
        'shows story option disabled and news option enabled if member has permission',
        (tester) async {
      mockNewsPostState.newsPostSpaceId = 'test-space-id';
      mockNewsStateNotifier.state = mockNewsPostState;
      when(() => mockMember.canString('CanPostNews')).thenReturn(true);
      when(() => mockMember.canString('CanPostStories')).thenReturn(false);

      await createWidgetUnderTest(tester);
      await tester.pumpAndSettle();

      final storyText = tester.widget<Text>(find.text('Story'));
      final boostText = tester.widget<Text>(find.text('Boost'));
      expect(
        storyText.style?.color,
        equals(
          Theme.of(tester.element(find.text('Story'))).disabledColor,
        ),
      );
      expect(
        boostText.style?.color,
        equals(
          Theme.of(tester.element(find.text('Boost'))).colorScheme.onSurface,
        ),
      );
    });
  });
}
