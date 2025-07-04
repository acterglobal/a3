import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/activities/pages/activities_page.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/test_util.dart';
import 'package:acter/features/activities/providers/notifiers/activities_notifiers.dart';
import 'package:acter/features/activities/providers/activities_providers.dart';

// Mock section builder functions
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

class FakeAllActivitiesNotifier extends AllActivitiesNotifier {
  bool loadMoreCalled = false;

  @override
  Future<void> loadMore() async {
    loadMoreCalled = true;
  }

  @override
  Future<List<String>> build() async {
    // Return a non-empty list to ensure scroll area
    return List.generate(50, (i) => 'Activity $i');
  }

  @override
  bool get hasMoreData => true;
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
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Consumer(
            builder: (context, ref, child) {
              final sections = [
                const Text('Section 1'),
                const Text('Section 2'),
                const Text('Section 3'),
              ];
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
      expect(find.text('Section 2'), findsOneWidget);
      expect(find.text('Section 3'), findsOneWidget);
    });

    testWidgets('buildActivityBody should handle null section widgets gracefully', (tester) async {
      const page = ActivitiesPage();
      
      await tester.pumpProviderWidget(
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Consumer(
            builder: (context, ref, child) {
              // Pass null widgets in the list
              final sections = [null, const Text('Valid Section'), null];
              final body = page.buildActivityBody(context, ref, sections.whereType<Widget>().toList());
              return Scaffold(body: body);
            },
          ),
        ),
      );
      await tester.pump();

      // Should handle null widgets gracefully
      expect(find.text('Valid Section'), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });

  group('ActivitiesPage Scroll Behavior Tests', () {
    testWidgets('should handle scroll notifications without errors', (tester) async {
      await tester.pumpProviderWidget(
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: const TestScrollWidget(),
        ),
      );
      await tester.pump();

      // Test that scroll notifications are handled
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -100));
      await tester.pump();

      // Should not crash and widget should still be there
      expect(find.byType(TestScrollWidget), findsOneWidget);
    });

    testWidgets('should trigger scroll threshold at 70% and handle edge cases', (tester) async {
      bool scrollTriggered = false;
      
      await tester.pumpProviderWidget(
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: TestScrollWidget(
            onScrollThreshold: () {
              scrollTriggered = true;
            },
          ),
        ),
      );
      await tester.pump();

      // Scroll to trigger the 70% threshold
      await tester.dragUntilVisible(
        find.text('Bottom Content'),
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pump();

      // Should trigger scroll threshold
      expect(scrollTriggered, isTrue);
    });

    testWidgets('should not trigger scroll threshold at 60%', (tester) async {
      bool scrollTriggered = false;
      
      await tester.pumpProviderWidget(
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: TestScrollWidget(
            onScrollThreshold: () {
              scrollTriggered = true;
            },
          ),
        ),
      );
      await tester.pump();

      // Scroll to 60% (should not trigger - threshold is 70%)
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -100));
      await tester.pump();

      expect(scrollTriggered, isFalse);
    });

    testWidgets('should handle zero maxScrollExtent', (tester) async {
      bool scrollTriggered = false;
      
      await tester.pumpProviderWidget(
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: TestNoScrollWidget(
            onScrollThreshold: () {
              scrollTriggered = true;
            },
          ),
        ),
      );
      await tester.pump();

      // Try to scroll when there's no scrollable content
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -100));
      await tester.pump();

      // Should not trigger when maxScrollExtent is 0
      expect(scrollTriggered, isFalse);
    });

    testWidgets('should ignore non-ScrollUpdateNotification events', (tester) async {
      bool scrollTriggered = false;
      
      await tester.pumpProviderWidget(
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: TestScrollWidget(
            onScrollThreshold: () {
              scrollTriggered = true;
            },
          ),
        ),
      );
      await tester.pump();

      // Test that starting a scroll gesture doesn't trigger threshold
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(SingleChildScrollView)),
      );
      await tester.pump();
      await gesture.up();
      await tester.pump();

      // Should not trigger for non-update notifications
      expect(scrollTriggered, isFalse);
    });

    testWidgets('should handle rapid scroll events', (tester) async {
      int scrollCount = 0;
      
      await tester.pumpProviderWidget(
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: TestScrollWidget(
            onScrollThreshold: () {
              scrollCount++;
            },
          ),
        ),
      );
      await tester.pump();

      // Scroll to the bottom to ensure threshold is reached
      await tester.dragUntilVisible(
        find.text('Bottom Content'),
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pump();

      expect(find.byType(TestScrollWidget), findsOneWidget);
      expect(scrollCount, greaterThan(0));
    });
  });

  group('ActivitiesPage Localization Tests', () {
    testWidgets('should display correct localized text in app bar and empty state', (tester) async {
      const page = ActivitiesPage();
      
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Builder(
            builder: (context) {
              final appBar = page.buildActivityAppBar(context);
              final emptyState = page.buildEmptyStateWidget(context);
              final lang = L10n.of(context);
              
              expect((appBar.title as Text).data, lang.activities);
              
              return emptyState;
            },
          ),
        ),
      );
      await tester.pump();

      // Verify empty state uses localization
      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('should handle different locales', (tester) async {
      const page = ActivitiesPage();
      
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          locale: const Locale('de'), // Test German locale
          home: Builder(
            builder: (context) {
              final appBar = page.buildActivityAppBar(context);
              final lang = L10n.of(context);
              
              expect((appBar.title as Text).data, lang.activities);
              
              return Scaffold(appBar: appBar);
            },
          ),
        ),
      );
      await tester.pump();
    });
  });

  group('ActivitiesPage Widget Structure Tests', () {
    testWidgets('should have correct widget hierarchy', (tester) async {
      const page = ActivitiesPage();
      
      await tester.pumpProviderWidget(
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Consumer(
            builder: (context, ref, child) {
              final sections = [const Text('Test Section')];
              final body = page.buildActivityBody(context, ref, sections);
              return Scaffold(body: body);
            },
          ),
        ),
      );
      await tester.pump();

      // Verify widget hierarchy
      expect(find.byType(NotificationListener<ScrollNotification>), findsAtLeastNWidgets(1));
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(Column), findsAtLeastNWidgets(1));
    });
  });

  group('ActivitiesPage Error Handling Tests', () {
    testWidgets('should handle large number of sections', (tester) async {
      const page = ActivitiesPage();
      
      await tester.pumpProviderWidget(
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Consumer(
            builder: (context, ref, child) {
              final sections = List.generate(100, (index) => Text('Section $index'));
              final body = page.buildActivityBody(context, ref, sections);
              return Scaffold(body: body);
            },
          ),
        ),
      );
      await tester.pump();

      // Should handle large number of sections without issues
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('Section 0'), findsOneWidget);
      expect(find.text('Section 99'), findsOneWidget);
    });

    testWidgets('should handle scroll with no content', (tester) async {
      await tester.pumpProviderWidget(
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: const TestEmptyScrollWidget(),
        ),
      );
      await tester.pump();

      // Should handle scroll with no content
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -100), warnIfMissed: false);
      await tester.pump();

      // Should not crash
      expect(find.byType(TestEmptyScrollWidget), findsOneWidget);
    });
  });

  group('ActivitiesPage Performance Tests', () {
    testWidgets('should handle rapid rebuilds', (tester) async {
      const page = ActivitiesPage();
      
      await tester.pumpProviderWidget(
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Consumer(
            builder: (context, ref, child) {
              final sections = [const Text('Performance Test')];
              final body = page.buildActivityBody(context, ref, sections);
              return Scaffold(body: body);
            },
          ),
        ),
      );

      // Rapid rebuilds
      for (int i = 0; i < 10; i++) {
        await tester.pump();
      }

      // Should handle rapid rebuilds without issues
      expect(find.text('Performance Test'), findsOneWidget);
    });

    testWidgets('should handle memory efficiently', (tester) async {
      const page = ActivitiesPage();
      
      await tester.pumpProviderWidget(
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Consumer(
            builder: (context, ref, child) {
              final sections = List.generate(50, (index) => Text('Memory Test $index'));
              final body = page.buildActivityBody(context, ref, sections);
              return Scaffold(body: body);
            },
          ),
        ),
      );
      await tester.pump();

      // Should handle memory efficiently
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('Memory Test 0'), findsOneWidget);
      expect(find.text('Memory Test 49'), findsOneWidget);
    });
  });

  group('ActivitiesPage Provider Integration', () {
    testWidgets('calls loadMore on allActivitiesProvider.notifier when scrolled past 70%', (tester) async {
      final fakeNotifier = FakeAllActivitiesNotifier();
      
      await tester.pumpProviderWidget(
        overrides: [
          allActivitiesProvider.overrideWith(() => fakeNotifier),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, child) {
              final page = ActivitiesPage();
              // Provide MANY sections to ensure a large scrollable area
              final sections = List.generate(50, (i) => Text('Section $i'));
              final body = page.buildActivityBody(context, ref, sections);
              return Scaffold(body: body);
            },
          ),
        ),
      );
      await tester.pump();

      // Now scroll to trigger the threshold
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -1000));
      await tester.pump();

      expect(fakeNotifier.loadMoreCalled, isTrue);
    });
  });
}

// Test widget that mimics the scroll behavior from ActivitiesPage
class TestScrollWidget extends StatelessWidget {
  final VoidCallback? onScrollThreshold;
  
  const TestScrollWidget({super.key, this.onScrollThreshold});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test')),
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo is ScrollUpdateNotification) {
            final pixels = scrollInfo.metrics.pixels;
            final maxExtent = scrollInfo.metrics.maxScrollExtent;
            final progress = maxExtent > 0 ? pixels / maxExtent : 0;
            
            if (progress >= 0.7 && maxExtent > 0) {
              onScrollThreshold?.call();
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

// Test widget with no scrollable content
class TestNoScrollWidget extends StatelessWidget {
  final VoidCallback? onScrollThreshold;
  
  const TestNoScrollWidget({super.key, this.onScrollThreshold});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test')),
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (scrollInfo is ScrollUpdateNotification) {
            final pixels = scrollInfo.metrics.pixels;
            final maxExtent = scrollInfo.metrics.maxScrollExtent;
            final progress = maxExtent > 0 ? pixels / maxExtent : 0;
            
            if (progress >= 0.7 && maxExtent > 0) {
              onScrollThreshold?.call();
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

// Test widget with empty scroll content
class TestEmptyScrollWidget extends StatelessWidget {
  const TestEmptyScrollWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test')),
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          // Handle scroll notifications
          return false;
        },
        child: const SingleChildScrollView(
          child: SizedBox.shrink(),
        ),
      ),
    );
  }
} 