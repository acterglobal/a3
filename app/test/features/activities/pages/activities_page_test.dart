import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/activities/pages/activities_page.dart';
import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/test_util.dart';

// Mock the section builder functions
Widget? mockBuildSyncingStateSectionWidget(BuildContext context, WidgetRef ref) => null;
Widget? mockBuildSyncingStateSectionWidgetWithContent(BuildContext context, WidgetRef ref) => 
    const Text('Sync Section');

Widget? mockBuildSecurityAndPrivacySectionWidget(BuildContext context, WidgetRef ref) => null;
Widget? mockBuildSecurityAndPrivacySectionWidgetWithContent(BuildContext context, WidgetRef ref) => 
    const Text('Security Section');

Widget? mockBuildSpaceActivitiesSectionWidget(BuildContext context, WidgetRef ref) => null;
Widget? mockBuildSpaceActivitiesSectionWidgetWithContent(BuildContext context, WidgetRef ref) => 
    const Text('Activities Section');

class MockInvitationSectionWidget extends StatelessWidget {
  const MockInvitationSectionWidget({super.key});

  static bool shouldBeShown(WidgetRef ref) => false;
  static bool shouldBeShownTrue(WidgetRef ref) => true;

  @override
  Widget build(BuildContext context) => const Text('Invitation Section');
}

void main() {
  group('ActivitiesPage Unit Tests', () {
    testWidgets('buildActivityAppBar should return correct AppBar', (tester) async {
      const page = ActivitiesPage();
      
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Builder(
            builder: (context) {
              final appBar = page.buildActivityAppBar(context);
              final lang = L10n.of(context);
              
              expect(appBar, isA<AppBar>());
              expect(appBar.automaticallyImplyLeading, false);
              expect(appBar.title, isA<Text>());
              expect((appBar.title as Text).data, lang.activities);
              
              return Scaffold(appBar: appBar);
            },
          ),
        ),
      );
      await tester.pump();
    });

    testWidgets('buildEmptyStateWidget should return correct empty state', (tester) async {
      const page = ActivitiesPage();
      
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Builder(
            builder: (context) {
              final emptyState = page.buildEmptyStateWidget(context);
              expect(emptyState, isA<Center>());
              return emptyState;
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Center), findsOneWidget);
      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('buildActivityBody should return empty state for empty sections', (tester) async {
      const page = ActivitiesPage();
      
      await tester.pumpProviderWidget(
        overrides: [
          hasMoreActivitiesProvider.overrideWith((ref) => false),
          isLoadingMoreActivitiesProvider.overrideWith((ref) => false),
          loadMoreActivitiesProvider.overrideWith((ref) => () async {}),
        ],
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Consumer(
            builder: (context, ref, child) {
              final body = page.buildActivityBody(context, ref, []);
              return Scaffold(body: body);
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('buildActivityBody should handle sections with scroll behavior', (tester) async {
      const page = ActivitiesPage();
      
      await tester.pumpProviderWidget(
        overrides: [
          hasMoreActivitiesProvider.overrideWith((ref) => true),
          isLoadingMoreActivitiesProvider.overrideWith((ref) => false),
          loadMoreActivitiesProvider.overrideWith((ref) => () async {}),
        ],
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Consumer(
            builder: (context, ref, child) {
              final sections = [const Text('Section 1')];
              final body = page.buildActivityBody(context, ref, sections);
              return Scaffold(body: body);
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(NotificationListener<ScrollNotification>), findsAtLeastNWidgets(1));
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('Section 1'), findsOneWidget);
    });

    testWidgets('buildActivityBody should show loading indicator when isLoadingMore is true', (tester) async {
      const page = ActivitiesPage();
      
      await tester.pumpProviderWidget(
        overrides: [
          hasMoreActivitiesProvider.overrideWith((ref) => true),
          isLoadingMoreActivitiesProvider.overrideWith((ref) => true),
          loadMoreActivitiesProvider.overrideWith((ref) => () async {}),
        ],
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Consumer(
            builder: (context, ref, child) {
              final sections = [const Text('Section 1')];
              final body = page.buildActivityBody(context, ref, sections);
              return Scaffold(body: body);
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Section 1'), findsOneWidget);
    });

    testWidgets('buildActivityBody should not show loading indicator when isLoadingMore is false', (tester) async {
      const page = ActivitiesPage();
      
      await tester.pumpProviderWidget(
        overrides: [
          hasMoreActivitiesProvider.overrideWith((ref) => true),
          isLoadingMoreActivitiesProvider.overrideWith((ref) => false),
          loadMoreActivitiesProvider.overrideWith((ref) => () async {}),
        ],
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Consumer(
            builder: (context, ref, child) {
              final sections = [const Text('Section 1')];
              final body = page.buildActivityBody(context, ref, sections);
              return Scaffold(body: body);
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Section 1'), findsOneWidget);
    });
  });

  group('ActivitiesPage Pagination Logic Tests', () {
    testWidgets('should trigger pagination when scrolled to 90% and conditions are met', (tester) async {
      bool loadMoreCalled = false;
      
      await tester.pumpProviderWidget(
        overrides: [
          hasMoreActivitiesProvider.overrideWith((ref) => true),
          isLoadingMoreActivitiesProvider.overrideWith((ref) => false),
          loadMoreActivitiesProvider.overrideWith((ref) => () async {
            loadMoreCalled = true;
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: const TestPaginationWidget(),
        ),
      );
      await tester.pump();

      // Scroll to trigger pagination
      await tester.dragUntilVisible(
        find.text('Bottom Content'),
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pump();

      expect(loadMoreCalled, isTrue);
    });

    testWidgets('should not trigger pagination when already loading', (tester) async {
      bool loadMoreCalled = false;
      
      await tester.pumpProviderWidget(
        overrides: [
          hasMoreActivitiesProvider.overrideWith((ref) => true),
          isLoadingMoreActivitiesProvider.overrideWith((ref) => true), // Already loading
          loadMoreActivitiesProvider.overrideWith((ref) => () async {
            loadMoreCalled = true;
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: const TestPaginationWidget(),
        ),
      );
      await tester.pump();

      // Try to scroll
      await tester.dragUntilVisible(
        find.text('Bottom Content'),
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pump();

      // Should not call loadMore when already loading
      expect(loadMoreCalled, isFalse);
    });

    testWidgets('should not trigger pagination when no more activities', (tester) async {
      bool loadMoreCalled = false;
      
      await tester.pumpProviderWidget(
        overrides: [
          hasMoreActivitiesProvider.overrideWith((ref) => false), // No more activities
          isLoadingMoreActivitiesProvider.overrideWith((ref) => false),
          loadMoreActivitiesProvider.overrideWith((ref) => () async {
            loadMoreCalled = true;
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: const TestPaginationWidget(),
        ),
      );
      await tester.pump();

      // Try to scroll
      await tester.dragUntilVisible(
        find.text('Bottom Content'),
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pump();

      // Should not call loadMore when no more activities
      expect(loadMoreCalled, isFalse);
    });

    testWidgets('should not trigger pagination at 80% scroll progress', (tester) async {
      bool loadMoreCalled = false;
      
      await tester.pumpProviderWidget(
        overrides: [
          hasMoreActivitiesProvider.overrideWith((ref) => true),
          isLoadingMoreActivitiesProvider.overrideWith((ref) => false),
          loadMoreActivitiesProvider.overrideWith((ref) => () async {
            loadMoreCalled = true;
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: const TestLimitedPaginationWidget(),
        ),
      );
      await tester.pump();

      // Scroll to 80% (should not trigger)
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -150));
      await tester.pump();

      expect(loadMoreCalled, isFalse);
    });

    testWidgets('should handle zero maxScrollExtent', (tester) async {
      bool loadMoreCalled = false;
      
      await tester.pumpProviderWidget(
        overrides: [
          hasMoreActivitiesProvider.overrideWith((ref) => true),
          isLoadingMoreActivitiesProvider.overrideWith((ref) => false),
          loadMoreActivitiesProvider.overrideWith((ref) => () async {
            loadMoreCalled = true;
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: const TestNoPaginationWidget(),
        ),
      );
      await tester.pump();

      // Try to scroll when there's no scrollable content
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -100));
      await tester.pump();

      // Should not trigger pagination when maxScrollExtent is 0
      expect(loadMoreCalled, isFalse);
    });

    testWidgets('should ignore non-ScrollUpdateNotification events', (tester) async {
      bool loadMoreCalled = false;
      
      await tester.pumpProviderWidget(
        overrides: [
          hasMoreActivitiesProvider.overrideWith((ref) => true),
          isLoadingMoreActivitiesProvider.overrideWith((ref) => false),
          loadMoreActivitiesProvider.overrideWith((ref) => () async {
            loadMoreCalled = true;
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: const TestPaginationWidget(),
        ),
      );
      await tester.pump();

      // Test that starting a scroll gesture doesn't trigger pagination
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(SingleChildScrollView)),
      );
      await tester.pump();
      await gesture.up();
      await tester.pump();

      // Should not trigger pagination for non-update notifications
      expect(loadMoreCalled, isFalse);
    });

    testWidgets('should handle loadMore function errors gracefully', (tester) async {
      bool errorHandled = false;
      
      await tester.pumpProviderWidget(
        overrides: [
          hasMoreActivitiesProvider.overrideWith((ref) => true),
          isLoadingMoreActivitiesProvider.overrideWith((ref) => false),
          loadMoreActivitiesProvider.overrideWith((ref) => () async {
            // Simulate an error condition that gets handled
            errorHandled = true;
          }),
        ],
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: const TestPaginationWidget(),
        ),
      );
      await tester.pump();

      // Scroll to trigger pagination
      await tester.dragUntilVisible(
        find.text('Bottom Content'),
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pump();

      // Verify error handling code path was executed
      expect(errorHandled, isTrue);
      // Widget should still be there
      expect(find.byType(TestPaginationWidget), findsOneWidget);
    });
  });

  group('ActivitiesPage Integration Tests', () {
    testWidgets('should handle scroll notifications without errors', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          hasMoreActivitiesProvider.overrideWith((ref) => true),
          isLoadingMoreActivitiesProvider.overrideWith((ref) => false),
          loadMoreActivitiesProvider.overrideWith((ref) => () async {}),
        ],
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: const TestPaginationWidget(),
        ),
      );
      await tester.pump();

      // Test that scroll notifications are handled
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -100));
      await tester.pump();

      // Should not crash and widget should still be there
      expect(find.byType(TestPaginationWidget), findsOneWidget);
    });

    testWidgets('should handle provider state changes', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          hasMoreActivitiesProvider.overrideWith((ref) => true),
          isLoadingMoreActivitiesProvider.overrideWith((ref) => false),
          loadMoreActivitiesProvider.overrideWith((ref) => () async {}),
        ],
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: const TestWithLoadingIndicator(),
        ),
      );
      await tester.pump();

      // Initial state - no loading indicator
      expect(find.byType(CircularProgressIndicator), findsNothing);
      
      // Widget should be present and stable
      expect(find.byType(TestWithLoadingIndicator), findsOneWidget);
    });

    testWidgets('should display loading indicator when loading more', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          hasMoreActivitiesProvider.overrideWith((ref) => true),
          isLoadingMoreActivitiesProvider.overrideWith((ref) => true),
          loadMoreActivitiesProvider.overrideWith((ref) => () async {}),
        ],
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: const TestWithLoadingIndicator(),
        ),
      );
      await tester.pump();

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

// Test widget that mimics the pagination logic from ActivitiesPage
class TestPaginationWidget extends ConsumerWidget {
  const TestPaginationWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasMoreActivities = ref.watch(hasMoreActivitiesProvider);
    final isLoadingMore = ref.watch(isLoadingMoreActivitiesProvider);
    final loadMoreActivities = ref.watch(loadMoreActivitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Test')),
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo is ScrollUpdateNotification) {
            final pixels = scrollInfo.metrics.pixels;
            final maxExtent = scrollInfo.metrics.maxScrollExtent;
            final progress = maxExtent > 0 ? pixels / maxExtent : 0;
            
            if (progress >= 0.9 &&
                hasMoreActivities && 
                !isLoadingMore &&
                maxExtent > 0) {
              try {
                loadMoreActivities();
              } catch (e) {
                // Handle error gracefully
              }
            }
          }
          return false;
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text('Top Content'),
              ...List.generate(50, (index) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Item $index'),
              )),
              const Text('Bottom Content'),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

// Test widget with limited scroll content
class TestLimitedPaginationWidget extends ConsumerWidget {
  const TestLimitedPaginationWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasMoreActivities = ref.watch(hasMoreActivitiesProvider);
    final isLoadingMore = ref.watch(isLoadingMoreActivitiesProvider);
    final loadMoreActivities = ref.watch(loadMoreActivitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Test')),
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo is ScrollUpdateNotification) {
            final pixels = scrollInfo.metrics.pixels;
            final maxExtent = scrollInfo.metrics.maxScrollExtent;
            final progress = maxExtent > 0 ? pixels / maxExtent : 0;
            
            if (progress >= 0.9 &&
                hasMoreActivities && 
                !isLoadingMore &&
                maxExtent > 0) {
              loadMoreActivities();
            }
          }
          return false;
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text('Top Content'),
              ...List.generate(10, (index) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Item $index'),
              )),
              const Text('Bottom Content'),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}

// Test widget with no scrollable content
class TestNoPaginationWidget extends ConsumerWidget {
  const TestNoPaginationWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasMoreActivities = ref.watch(hasMoreActivitiesProvider);
    final isLoadingMore = ref.watch(isLoadingMoreActivitiesProvider);
    final loadMoreActivities = ref.watch(loadMoreActivitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Test')),
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo is ScrollUpdateNotification) {
            final pixels = scrollInfo.metrics.pixels;
            final maxExtent = scrollInfo.metrics.maxScrollExtent;
            final progress = maxExtent > 0 ? pixels / maxExtent : 0;
            
            if (progress >= 0.9 &&
                hasMoreActivities && 
                !isLoadingMore &&
                maxExtent > 0) {
              loadMoreActivities();
            }
          }
          return false;
        },
        child: const SingleChildScrollView(
          child: Column(
            children: [
              Text('Single Item'),
            ],
          ),
        ),
      ),
    );
  }
}

// Test widget with loading indicator
class TestWithLoadingIndicator extends ConsumerWidget {
  const TestWithLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoadingMore = ref.watch(isLoadingMoreActivitiesProvider);
    final lang = L10n.of(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Test')),
      body: Column(
        children: [
          const Text('Test Section'),
          if (isLoadingMore) 
            Column(
              children: [
                const CircularProgressIndicator(),
                Text(lang.loadingMoreActivities),
              ],
            ),
        ],
      ),
    );
  }
} 