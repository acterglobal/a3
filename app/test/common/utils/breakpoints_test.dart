import 'package:acter/common/utils/breakpoints.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActerBreakpoints', () {
    Widget buildTestWidget(Size size, {required Widget child}) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: Scaffold(body: child),
        ),
      );
    }

    group('Breakpoint Detection', () {
      testWidgets('detects small screens correctly', (tester) async {
        // Test small screen (mobile)
        await tester.pumpWidget(
          buildTestWidget(
            const Size(400, 800),
            child: Builder(
              builder: (context) {
                expect(ActerBreakpoints.isSmall(context), true);
                expect(ActerBreakpoints.isMedium(context), false);
                expect(ActerBreakpoints.isMediumLarge(context), false);
                expect(ActerBreakpoints.isLarge(context), false);
                expect(ActerBreakpoints.isExtraLarge(context), false);
                expect(ActerBreakpoints.isLargeScreen(context), false);
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('detects medium screens correctly', (tester) async {
        // Test medium screen (tablet portrait)
        await tester.pumpWidget(
          buildTestWidget(
            const Size(700, 800),
            child: Builder(
              builder: (context) {
                expect(ActerBreakpoints.isSmall(context), false);
                expect(ActerBreakpoints.isMedium(context), true);
                expect(ActerBreakpoints.isMediumLarge(context), false);
                expect(ActerBreakpoints.isLarge(context), false);
                expect(ActerBreakpoints.isExtraLarge(context), false);
                expect(ActerBreakpoints.isLargeScreen(context), false);
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('detects medium-large screens correctly', (tester) async {
        // Test medium-large screen (tablet landscape)
        await tester.pumpWidget(
          buildTestWidget(
            const Size(1000, 800),
            child: Builder(
              builder: (context) {
                expect(ActerBreakpoints.isSmall(context), false);
                expect(ActerBreakpoints.isMedium(context), false);
                expect(ActerBreakpoints.isMediumLarge(context), true);
                expect(ActerBreakpoints.isLarge(context), false);
                expect(ActerBreakpoints.isExtraLarge(context), false);
                expect(ActerBreakpoints.isLargeScreen(context), true);
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('detects large screens correctly', (tester) async {
        // Test large screen (desktop)
        await tester.pumpWidget(
          buildTestWidget(
            const Size(1400, 1000),
            child: Builder(
              builder: (context) {
                expect(ActerBreakpoints.isSmall(context), false);
                expect(ActerBreakpoints.isMedium(context), false);
                expect(ActerBreakpoints.isMediumLarge(context), false);
                expect(ActerBreakpoints.isLarge(context), true);
                expect(ActerBreakpoints.isExtraLarge(context), false);
                expect(ActerBreakpoints.isLargeScreen(context), true);
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('detects extra large screens correctly', (tester) async {
        // Test extra large screen
        await tester.pumpWidget(
          buildTestWidget(
            const Size(1800, 1200),
            child: Builder(
              builder: (context) {
                expect(ActerBreakpoints.isSmall(context), false);
                expect(ActerBreakpoints.isMedium(context), false);
                expect(ActerBreakpoints.isMediumLarge(context), false);
                expect(ActerBreakpoints.isLarge(context), false);
                expect(ActerBreakpoints.isExtraLarge(context), true);
                expect(ActerBreakpoints.isLargeScreen(context), true);
                return const SizedBox();
              },
            ),
          ),
        );
      });
    });

    group('Navigation Layout Logic', () {
      testWidgets('shows bottom navigation for small screens', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            const Size(400, 800),
            child: Builder(
              builder: (context) {
                expect(ActerBreakpoints.shouldShowBottomNavigation(context), true);
                expect(ActerBreakpoints.shouldShowSidebar(context), false);
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('shows bottom navigation for medium screens', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            const Size(700, 800),
            child: Builder(
              builder: (context) {
                expect(ActerBreakpoints.shouldShowBottomNavigation(context), true);
                expect(ActerBreakpoints.shouldShowSidebar(context), false);
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('shows sidebar for medium-large screens and up', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            const Size(1300, 800),
            child: Builder(
              builder: (context) {
                expect(ActerBreakpoints.shouldShowBottomNavigation(context), false);
                expect(ActerBreakpoints.shouldShowSidebar(context), true);
                return const SizedBox();
              },
            ),
          ),
        );
      });
    });

    group('Responsive Dimensions', () {
      testWidgets('calculates chat message width correctly for small screens', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            const Size(400, 800),
            child: Builder(
              builder: (context) {
                final width = ActerBreakpoints.getChatMessageWidth(context);
                expect(width, 400 * 0.75); // 75% for small screens
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('calculates chat message width correctly for large screens', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            const Size(1200, 800),
            child: Builder(
              builder: (context) {
                final width = ActerBreakpoints.getChatMessageWidth(context);
                expect(width, 1200 * 0.5); // 50% for large screens
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('calculates side sheet width correctly', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            const Size(800, 600),
            child: Builder(
              builder: (context) {
                final width = ActerBreakpoints.getSideSheetWidth(context);
                final calculatedWidth = 800 / 1.4; // 571.4
                final expectedWidth = calculatedWidth > 450 ? 450.0 : calculatedWidth;
                expect(width, expectedWidth);
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('enforces minimum side sheet width', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            const Size(200, 400), // Very small screen
            child: Builder(
              builder: (context) {
                final width = ActerBreakpoints.getSideSheetWidth(context);
                expect(width, 200 * 0.95); // Should use 95% fallback
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('enforces maximum side sheet width', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            const Size(2000, 1200), // Very large screen
            child: Builder(
              builder: (context) {
                final width = ActerBreakpoints.getSideSheetWidth(context);
                expect(width, 450); // Should cap at maxSideSheet
                return const SizedBox();
              },
            ),
          ),
        );
      });
    });

    group('Breakpoint Boundary Testing', () {
      testWidgets('handles exact breakpoint boundaries', (tester) async {
        // Test exact small/medium boundary (600px)
        await tester.pumpWidget(
          buildTestWidget(
            const Size(600, 800),
            child: Builder(
              builder: (context) {
                expect(ActerBreakpoints.isSmall(context), false);
                expect(ActerBreakpoints.isMedium(context), true);
                return const SizedBox();
              },
            ),
          ),
        );

        // Test exact medium/medium-large boundary (840px)
        await tester.pumpWidget(
          buildTestWidget(
            const Size(840, 800),
            child: Builder(
              builder: (context) {
                expect(ActerBreakpoints.isMedium(context), false);
                expect(ActerBreakpoints.isMediumLarge(context), true);
                return const SizedBox();
              },
            ),
          ),
        );

        // Test exact medium-large/large boundary (1200px)
        await tester.pumpWidget(
          buildTestWidget(
            const Size(1200, 800),
            child: Builder(
              builder: (context) {
                expect(ActerBreakpoints.isMediumLarge(context), false);
                expect(ActerBreakpoints.isLarge(context), true);
                return const SizedBox();
              },
            ),
          ),
        );

        // Test exact large/extra-large boundary (1600px)
        await tester.pumpWidget(
          buildTestWidget(
            const Size(1600, 800),
            child: Builder(
              builder: (context) {
                expect(ActerBreakpoints.isLarge(context), false);
                expect(ActerBreakpoints.isExtraLarge(context), true);
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('handles custom large screen boundary (770px)', (tester) async {
        // Just below custom large screen threshold
        await tester.pumpWidget(
          buildTestWidget(
            const Size(769, 800),
            child: Builder(
              builder: (context) {
                expect(ActerBreakpoints.isLargeScreen(context), false);
                return const SizedBox();
              },
            ),
          ),
        );

        // At custom large screen threshold
        await tester.pumpWidget(
          buildTestWidget(
            const Size(770, 800),
            child: Builder(
              builder: (context) {
                expect(ActerBreakpoints.isLargeScreen(context), true);
                return const SizedBox();
              },
            ),
          ),
        );
      });
    });

    group('Constants Validation', () {
      test('validates breakpoint constants are in ascending order', () {
        expect(ActerBreakpoints.small, lessThan(ActerBreakpoints.medium));
        expect(ActerBreakpoints.medium, lessThan(ActerBreakpoints.mediumLarge));
        expect(ActerBreakpoints.mediumLarge, lessThan(ActerBreakpoints.large));
      });

      test('validates side sheet constraints', () {
        expect(ActerBreakpoints.sideSheet, lessThan(ActerBreakpoints.maxSideSheet));
      });
    });
  });

  group('ActerAnimations', () {
    testWidgets('has correct transition duration', (tester) async {
      expect(ActerAnimations.transitionDuration, const Duration(milliseconds: 300));
    });
  });
} 