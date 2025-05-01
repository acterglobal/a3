import 'package:acter/features/onboarding/pages/recommended_spaces_page.dart';
import 'package:acter/features/public_room_search/models/public_search_filters.dart';
import 'package:acter/features/public_room_search/providers/public_search_providers.dart';
import 'package:acter/features/public_room_search/models/publiic_search_result_state.dart';
import 'package:acter/features/public_room_search/providers/notifiers/public_search_filters_notifier.dart';
import 'package:acter/features/public_room_search/providers/notifiers/public_spaces_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/test_util.dart';

/// Mock class for PublicSearchResultItem to simulate space data
class MockPublicSearchResultItem extends Mock implements PublicSearchResultItem {}

void main() {
  late MockPublicSearchResultItem mockSpace;

  /// Setup mock data before each test
  setUp(() {
    mockSpace = MockPublicSearchResultItem();
    
    // Setup mock space data with test values
    when(() => mockSpace.name()).thenReturn('Test Space');
    when(() => mockSpace.topic()).thenReturn('Test Description');
    when(() => mockSpace.roomIdStr()).thenReturn('!test:acter.global');
  });

  /// Test that the page displays the correct title
  testWidgets('RecommendedSpacesPage shows correct title and description',
      (WidgetTester tester) async {
    await tester.pumpProviderWidget(
      child: RecommendedSpacesPage(callNextPage: () {}),
    );

    expect(find.text('Recommended Spaces'), findsOneWidget);
  });

  /// Test that the loading indicator is shown when the page is in loading state
  testWidgets('RecommendedSpacesPage shows loading indicator when loading',
      (WidgetTester tester) async {
    await tester.pumpProviderWidget(
      child: RecommendedSpacesPage(callNextPage: () {}),
      overrides: [
        searchFilterProvider.overrideWith((ref) {
          final notifier = PublicSearchFiltersNotifier();
          notifier.updateSearchTerm('acter.global');
          notifier.updateSearchServer('acter.global');
          notifier.updateFilters(FilterBy.spaces);
          return notifier;
        }),
        publicSearchProvider.overrideWith((ref) {
          final notifier = PublicSearchNotifier(ref);
          notifier.state = PublicSearchResultState(
            records: [],
            filter: PublicSearchFilters(
              searchTerm: 'acter.global',
              server: 'acter.global',
              filterBy: FilterBy.spaces,
            ),
            loading: true,
          );
          return notifier;
        }),
      ],
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  /// Test that a space tile is displayed with correct name and description when data is loaded
  testWidgets('RecommendedSpacesPage shows space tile when data is loaded',
      (WidgetTester tester) async {
    await tester.pumpProviderWidget(
      child: RecommendedSpacesPage(callNextPage: () {}),
      overrides: [
        searchFilterProvider.overrideWith((ref) => PublicSearchFiltersNotifier()),
        publicSearchProvider.overrideWith((ref) {
          final notifier = PublicSearchNotifier(ref);
          notifier.state = PublicSearchResultState(
            records: [mockSpace],
            filter: const PublicSearchFilters(),
          );
          return notifier;
        }),
      ],
    );

    expect(find.text('Test Space'), findsOneWidget);
    expect(find.text('Test Description'), findsOneWidget);
  });

  /// Test that "No spaces found" message is shown when there are no spaces to display
  testWidgets('RecommendedSpacesPage shows "No Spaces Found" when no data',
      (WidgetTester tester) async {
    await tester.pumpProviderWidget(
      child: RecommendedSpacesPage(callNextPage: () {}),
      overrides: [
        searchFilterProvider.overrideWith((ref) => PublicSearchFiltersNotifier()),
        publicSearchProvider.overrideWith((ref) {
          final notifier = PublicSearchNotifier(ref);
          notifier.state = PublicSearchResultState(
            records: [],
            filter: const PublicSearchFilters(),
          );
          return notifier;
        }),
      ],
    );

    expect(find.text('No spaces found'), findsOneWidget);
  });

  /// Test that both action buttons ("Join & Continue" and "Skip") are present
  testWidgets('RecommendedSpacesPage shows action buttons',
      (WidgetTester tester) async {
    await tester.pumpProviderWidget(
      child: RecommendedSpacesPage(callNextPage: () {}),
      overrides: [
        searchFilterProvider.overrideWith((ref) => PublicSearchFiltersNotifier()),
        publicSearchProvider.overrideWith((ref) {
          final notifier = PublicSearchNotifier(ref);
          notifier.state = PublicSearchResultState(
            records: [],
            filter: const PublicSearchFilters(),
          );
          return notifier;
        }),
      ],
    );

    expect(find.text('Join & Continue'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });
}
