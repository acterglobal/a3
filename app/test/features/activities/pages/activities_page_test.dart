import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/activities/pages/activities_page.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/test_util.dart';
import 'package:acter/features/activities/providers/activities_providers.dart';
import '../mock_data/mock_allActivity_notifier.dart';

// Mock section builder functions
Widget? mockBuildSyncingStateSectionWidget(
  BuildContext context,
  WidgetRef ref,
) => null;

Widget? mockBuildSyncingStateSectionWidgetWithContent(
  BuildContext context,
  WidgetRef ref,
) => const Text('Sync Section');

Widget? mockBuildSecurityAndPrivacySectionWidget(
  BuildContext context,
  WidgetRef ref,
) => null;

Widget? mockBuildSecurityAndPrivacySectionWidgetWithContent(
  BuildContext context,
  WidgetRef ref,
) => const Text('Security Section');

Widget? mockBuildSpaceActivitiesSectionWidget(
  BuildContext context,
  WidgetRef ref,
) => null;

Widget? mockBuildSpaceActivitiesSectionWidgetWithContent(
  BuildContext context,
  WidgetRef ref,
) => const Text('Activities Section');

class MockInvitationSectionWidget extends StatelessWidget {
  const MockInvitationSectionWidget({super.key});

  static bool shouldBeShown(WidgetRef ref) => false;

  static bool shouldBeShownTrue(WidgetRef ref) => true;

  @override
  Widget build(BuildContext context) => const Text('Invitation Section');
}

// Mock widget that provides scrollable content
class MockScrollableContent extends StatelessWidget {
  const MockScrollableContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        60,
        (index) => Container(
          height: 150,
          margin: const EdgeInsets.all(8),
          color: Colors.grey[300],
          child: Center(child: Text('Content $index')),
        ),
      ),
    );
  }
}

void main() {
  group('ActivitiesPage Unit Tests', () {
    testWidgets('buildActivityAppBar should return correct AppBar', (
      tester,
    ) async {
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

    testWidgets('buildEmptyStateWidget should return correct empty state', (
      tester,
    ) async {
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

    testWidgets(
      'buildActivityBody should return empty state for empty sections',
      (tester) async {
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
      },
    );

    testWidgets(
      'buildActivityBody should handle sections with scroll behavior',
      (tester) async {
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

        expect(
          find.byType(NotificationListener<ScrollNotification>),
          findsAtLeastNWidgets(1),
        );
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(find.text('Section 1'), findsOneWidget);
        expect(find.text('Section 2'), findsOneWidget);
        expect(find.text('Section 3'), findsOneWidget);
      },
    );

    testWidgets('buildActivityBody should handle null section widgets', (
      tester,
    ) async {
      const page = ActivitiesPage();

      await tester.pumpProviderWidget(
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Consumer(
            builder: (context, ref, child) {
              // Pass null widgets in the list
              final sections = [null, const Text('Valid Section'), null];
              final body = page.buildActivityBody(
                context,
                ref,
                sections.whereType<Widget>().toList(),
              );
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
    testWidgets('should handle scroll notifications without errors', (
      tester,
    ) async {
      final fakeNotifier = FakeAllActivitiesNotifier();

      await tester.pumpProviderWidget(
        overrides: [allActivitiesProvider.overrideWith(() => fakeNotifier)],
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Consumer(
            builder: (context, ref, child) {
              // Create a scrollable page with mock content
              return Scaffold(
                appBar: const ActivitiesPage().buildActivityAppBar(context),
                body: const ActivitiesPage().buildActivityBody(context, ref, [
                  const MockScrollableContent(),
                ]),
              );
            },
          ),
        ),
      );
      await tester.pump();

      // Test that scroll notifications are handled
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );
      await tester.pump();

      // Should not crash and widget should still be there
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('should have scroll notification listener', (tester) async {
      final fakeNotifier = FakeAllActivitiesNotifier();

      await tester.pumpProviderWidget(
        overrides: [allActivitiesProvider.overrideWith(() => fakeNotifier)],
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Consumer(
            builder: (context, ref, child) {
              // Create a scrollable page with mock content
              return Scaffold(
                appBar: const ActivitiesPage().buildActivityAppBar(context),
                body: const ActivitiesPage().buildActivityBody(context, ref, [
                  const MockScrollableContent(),
                ]),
              );
            },
          ),
        ),
      );
      await tester.pump();

      // Should have scroll notification listener
      expect(
        find.byType(NotificationListener<ScrollNotification>),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should handle scroll events without crashing', (tester) async {
      final fakeNotifier = FakeAllActivitiesNotifier();

      await tester.pumpProviderWidget(
        overrides: [allActivitiesProvider.overrideWith(() => fakeNotifier)],
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Consumer(
            builder: (context, ref, child) {
              // Create a scrollable page with mock content
              return Scaffold(
                appBar: const ActivitiesPage().buildActivityAppBar(context),
                body: const ActivitiesPage().buildActivityBody(context, ref, [
                  const MockScrollableContent(),
                ]),
              );
            },
          ),
        ),
      );
      await tester.pump();

      // Test various scroll distances
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -500),
      );
      await tester.pump();

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -1000),
      );
      await tester.pump();

      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -2000),
      );
      await tester.pump();

      // Should not crash
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('should not trigger loadMoreActivities when hasMore is false', (
      tester,
    ) async {
      final fakeNotifier = FakeAllActivitiesNotifier(hasMore: false);

      await tester.pumpProviderWidget(
        overrides: [allActivitiesProvider.overrideWith(() => fakeNotifier)],
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Consumer(
            builder: (context, ref, child) {
              return Scaffold(
                appBar: const ActivitiesPage().buildActivityAppBar(context),
                body: const ActivitiesPage().buildActivityBody(context, ref, [
                  const MockScrollableContent(),
                ]),
              );
            },
          ),
        ),
      );
      await tester.pump();

      // Scroll to trigger load more (80% threshold)
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -3000),
      );
      await tester.pump();

      // Should not trigger load more when hasMore is false
      expect(fakeNotifier.loadMoreCalled, isFalse);
    });

    testWidgets('should handle scroll notification with maxScroll = 0', (
      tester,
    ) async {
      final fakeNotifier = FakeAllActivitiesNotifier();
      fakeNotifier.setHasMore(true);

      await tester.pumpProviderWidget(
        overrides: [allActivitiesProvider.overrideWith(() => fakeNotifier)],
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Consumer(
            builder: (context, ref, child) {
              return Scaffold(
                appBar: const ActivitiesPage().buildActivityAppBar(context),
                body: const ActivitiesPage().buildActivityBody(
                  context,
                  ref,
                  [
                    const Text('Small content'),
                  ], // Small content to have maxScroll = 0
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();

      // Try to scroll (should not trigger load more when maxScroll = 0)
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );
      await tester.pump();

      // Should not trigger load more when maxScroll = 0
      expect(fakeNotifier.loadMoreCalled, isFalse);
    });

    testWidgets(
      'should handle scroll notification with pixels below 80% threshold',
      (tester) async {
        final fakeNotifier = FakeAllActivitiesNotifier();
        fakeNotifier.setHasMore(true);

        await tester.pumpProviderWidget(
          overrides: [allActivitiesProvider.overrideWith(() => fakeNotifier)],
          child: MaterialApp(
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            home: Consumer(
              builder: (context, ref, child) {
                return Scaffold(
                  appBar: const ActivitiesPage().buildActivityAppBar(context),
                  body: const ActivitiesPage().buildActivityBody(context, ref, [
                    const MockScrollableContent(),
                  ]),
                );
              },
            ),
          ),
        );
        await tester.pump();

        // Scroll to a small distance (below 80% threshold)
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -100),
        );
        await tester.pump();

        // Should not trigger load more when below threshold
        expect(fakeNotifier.loadMoreCalled, isFalse);
      },
    );
  });

  group('ActivitiesPage Provider Integration Tests', () {
    testWidgets(
      'should show circular progress indicator when hasMore is true',
      (tester) async {
        final fakeNotifier = FakeAllActivitiesNotifier();
        fakeNotifier.setHasMore(true);

        await tester.pumpProviderWidget(
          overrides: [allActivitiesProvider.overrideWith(() => fakeNotifier)],
          child: MaterialApp(
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            home: Consumer(
              builder: (context, ref, child) {
                // Create a scrollable page with mock content
                return Scaffold(
                  appBar: const ActivitiesPage().buildActivityAppBar(context),
                  body: const ActivitiesPage().buildActivityBody(context, ref, [
                    const MockScrollableContent(),
                  ]),
                );
              },
            ),
          ),
        );
        await tester.pump();

        // Should show circular progress indicator when hasMore is true
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets('should show "no more activities" text when hasMore is false', (
      tester,
    ) async {
      final fakeNotifier = FakeAllActivitiesNotifier(hasMore: false);

      await tester.pumpProviderWidget(
        overrides: [allActivitiesProvider.overrideWith(() => fakeNotifier)],
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Consumer(
            builder: (context, ref, child) {
              return Scaffold(
                appBar: const ActivitiesPage().buildActivityAppBar(context),
                body: const ActivitiesPage().buildActivityBody(context, ref, [
                  const MockScrollableContent(),
                ]),
              );
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('No more activities'), findsOneWidget);
    });

    testWidgets('should integrate with allActivitiesProvider correctly', (
      tester,
    ) async {
      final fakeNotifier = FakeAllActivitiesNotifier();
      fakeNotifier.setHasMore(true);

      await tester.pumpProviderWidget(
        overrides: [allActivitiesProvider.overrideWith(() => fakeNotifier)],
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Consumer(
            builder: (context, ref, child) {
              // Create a scrollable page with mock content
              return Scaffold(
                appBar: const ActivitiesPage().buildActivityAppBar(context),
                body: const ActivitiesPage().buildActivityBody(context, ref, [
                  const MockScrollableContent(),
                ]),
              );
            },
          ),
        ),
      );
      await tester.pump();

      // Should integrate with provider correctly
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(fakeNotifier.hasMore, isTrue);
    });

    testWidgets('should handle provider state changes', (tester) async {
      final fakeNotifier = FakeAllActivitiesNotifier();
      fakeNotifier.setHasMore(true);

      await tester.pumpProviderWidget(
        overrides: [allActivitiesProvider.overrideWith(() => fakeNotifier)],
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Consumer(
            builder: (context, ref, child) {
              // Create a scrollable page with mock content
              return Scaffold(
                appBar: const ActivitiesPage().buildActivityAppBar(context),
                body: const ActivitiesPage().buildActivityBody(context, ref, [
                  const MockScrollableContent(),
                ]),
              );
            },
          ),
        ),
      );
      await tester.pump();

      // Initially should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
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
              final sections = List.generate(
                100,
                (index) => Text('Section $index'),
              );
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
      final fakeNotifier = FakeAllActivitiesNotifier();

      await tester.pumpProviderWidget(
        overrides: [allActivitiesProvider.overrideWith(() => fakeNotifier)],
        child: MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Consumer(
            builder: (context, ref, child) {
              // Test with empty sections
              return Scaffold(
                appBar: const ActivitiesPage().buildActivityAppBar(context),
                body: const ActivitiesPage().buildActivityBody(
                  context,
                  ref,
                  [],
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();

      // Should handle scroll with no content
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
        warnIfMissed: false,
      );
      await tester.pump();

      // Should not crash
      expect(find.byType(EmptyState), findsOneWidget);
    });
  });
  testWidgets('should test buildActivityBody with scroll notification logic', (
    tester,
  ) async {
    final fakeNotifier = FakeAllActivitiesNotifier();
    fakeNotifier.setHasMore(true);

    await tester.pumpProviderWidget(
      overrides: [allActivitiesProvider.overrideWith(() => fakeNotifier)],
      child: MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Consumer(
          builder: (context, ref, child) {
            // Test the scroll notification logic by creating a large scrollable content
            return Scaffold(
              appBar: const ActivitiesPage().buildActivityAppBar(context),
              body: const ActivitiesPage().buildActivityBody(context, ref, [
                const MockScrollableContent(),
              ]),
            );
          },
        ),
      ),
    );
    await tester.pump();

    // Test scroll notification with different conditions
    // This covers the scroll notification logic in buildActivityBody
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -100),
    );
    await tester.pump();

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -2000),
    );
    await tester.pump();

    // Should handle scroll notifications properly
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
