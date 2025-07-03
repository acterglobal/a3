import 'package:acter/common/utils/breakpoints.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppShell Responsive Behavior Tests', () {
    Widget buildTestWidget(Size size, {required Widget child}) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: Scaffold(body: child),
        ),
      );
    }

    group('Breakpoint Constants', () {
      test('validates breakpoint constants are correct', () {
        expect(ActerBreakpoints.small, 600);
        expect(ActerBreakpoints.medium, 840);
        expect(ActerBreakpoints.mediumLarge, 1200);
        expect(ActerBreakpoints.large, 1600);
        expect(ActerBreakpoints.largeScreen, 770);
        expect(ActerBreakpoints.dashboard, 770);
        expect(ActerBreakpoints.sideSheet, 300);
        expect(ActerBreakpoints.maxSideSheet, 450);
      });

      test('validates animation duration', () {
        expect(ActerAnimations.transitionDuration, const Duration(milliseconds: 300));
      });
    });

    group('Breakpoint Detection', () {
      testWidgets('detects small screens correctly (mobile)', (tester) async {
        for (final width in [320, 400, 500, 599]) {
          await tester.pumpWidget(
            buildTestWidget(
              Size(width.toDouble(), 800),
              child: Builder(
                builder: (context) {
                  expect(ActerBreakpoints.isSmall(context), true, reason: 'Width $width should be small');
                  expect(ActerBreakpoints.isMedium(context), false);
                  expect(ActerBreakpoints.isMediumLarge(context), false);
                  expect(ActerBreakpoints.isLarge(context), false);
                  expect(ActerBreakpoints.isExtraLarge(context), false);
                  return const SizedBox();
                },
              ),
            ),
          );
        }
      });

      testWidgets('detects medium screens correctly (tablet portrait)', (tester) async {
        for (final width in [600, 700, 800, 839]) {
          await tester.pumpWidget(
            buildTestWidget(
              Size(width.toDouble(), 800),
              child: Builder(
                builder: (context) {
                  expect(ActerBreakpoints.isSmall(context), false);
                  expect(ActerBreakpoints.isMedium(context), true, reason: 'Width $width should be medium');
                  expect(ActerBreakpoints.isMediumLarge(context), false);
                  expect(ActerBreakpoints.isLarge(context), false);
                  expect(ActerBreakpoints.isExtraLarge(context), false);
                  return const SizedBox();
                },
              ),
            ),
          );
        }
      });

      testWidgets('detects medium-large screens correctly (tablet landscape)', (tester) async {
        for (final width in [840, 1000, 1100, 1199]) {
          await tester.pumpWidget(
            buildTestWidget(
              Size(width.toDouble(), 800),
              child: Builder(
                builder: (context) {
                  expect(ActerBreakpoints.isSmall(context), false);
                  expect(ActerBreakpoints.isMedium(context), false);
                  expect(ActerBreakpoints.isMediumLarge(context), true, reason: 'Width $width should be medium-large');
                  expect(ActerBreakpoints.isLarge(context), false);
                  expect(ActerBreakpoints.isExtraLarge(context), false);
                  return const SizedBox();
                },
              ),
            ),
          );
        }
      });

      testWidgets('detects large screens correctly (desktop)', (tester) async {
        for (final width in [1200, 1300, 1400, 1599]) {
          await tester.pumpWidget(
            buildTestWidget(
              Size(width.toDouble(), 800),
              child: Builder(
                builder: (context) {
                  expect(ActerBreakpoints.isSmall(context), false);
                  expect(ActerBreakpoints.isMedium(context), false);
                  expect(ActerBreakpoints.isMediumLarge(context), false);
                  expect(ActerBreakpoints.isLarge(context), true, reason: 'Width $width should be large');
                  expect(ActerBreakpoints.isExtraLarge(context), false);
                  return const SizedBox();
                },
              ),
            ),
          );
        }
      });

      testWidgets('detects extra large screens correctly', (tester) async {
        for (final width in [1600, 1800, 2000, 2400]) {
          await tester.pumpWidget(
            buildTestWidget(
              Size(width.toDouble(), 800),
              child: Builder(
                builder: (context) {
                  expect(ActerBreakpoints.isSmall(context), false);
                  expect(ActerBreakpoints.isMedium(context), false);
                  expect(ActerBreakpoints.isMediumLarge(context), false);
                  expect(ActerBreakpoints.isLarge(context), false);
                  expect(ActerBreakpoints.isExtraLarge(context), true, reason: 'Width $width should be extra large');
                  return const SizedBox();
                },
                             ),
             ),
           );
         }
       });
     });

    group('Navigation Layout Logic', () {
      testWidgets('shows bottom navigation for small and medium screens', (tester) async {
        final smallMediumWidths = [320, 400, 600, 700, 840, 1000, 1199];
        
        for (final width in smallMediumWidths) {
          await tester.pumpWidget(
            buildTestWidget(
              Size(width.toDouble(), 800),
              child: Builder(
                builder: (context) {
                  expect(ActerBreakpoints.shouldShowBottomNavigation(context), true, 
                    reason: 'Width $width should show bottom navigation');
                  expect(ActerBreakpoints.shouldShowSidebar(context), false,
                    reason: 'Width $width should NOT show sidebar');
                  return const SizedBox();
                },
              ),
            ),
          );
        }
      });

      testWidgets('shows sidebar for large screens', (tester) async {
        final largeWidths = [1200, 1300, 1400, 1600, 1800, 2000];
        
        for (final width in largeWidths) {
          await tester.pumpWidget(
            buildTestWidget(
              Size(width.toDouble(), 800),
              child: Builder(
                builder: (context) {
                  expect(ActerBreakpoints.shouldShowBottomNavigation(context), false,
                    reason: 'Width $width should NOT show bottom navigation');
                  expect(ActerBreakpoints.shouldShowSidebar(context), true,
                    reason: 'Width $width should show sidebar');
                  return const SizedBox();
                },
              ),
            ),
          );
        }
      });

      testWidgets('tests exact breakpoint boundaries', (tester) async {
        // Test 1199px vs 1200px (critical boundary)
        await tester.pumpWidget(
          buildTestWidget(
            const Size(1199, 800),
            child: Builder(
              builder: (context) {
                expect(ActerBreakpoints.shouldShowBottomNavigation(context), true);
                expect(ActerBreakpoints.shouldShowSidebar(context), false);
                return const SizedBox();
              },
            ),
          ),
        );

        await tester.pumpWidget(
          buildTestWidget(
            const Size(1200, 800),
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

    group('Dashboard Large Screen Detection', () {
      testWidgets('tests dashboard breakpoint boundary (770px)', (tester) async {
        // Test just below dashboard threshold
        for (final width in [760, 769]) {
          await tester.pumpWidget(
            buildTestWidget(
              Size(width.toDouble(), 800),
              child: Builder(
                builder: (context) {
                  expect(ActerBreakpoints.isLargeScreen(context), false,
                    reason: 'Width $width should NOT be large screen');
                  return const SizedBox();
                },
              ),
            ),
          );
        }

        // Test at and above dashboard threshold
        for (final width in [770, 800, 1000, 1200]) {
          await tester.pumpWidget(
            buildTestWidget(
              Size(width.toDouble(), 800),
              child: Builder(
                builder: (context) {
                  expect(ActerBreakpoints.isLargeScreen(context), true,
                    reason: 'Width $width should be large screen');
                  return const SizedBox();
                },
              ),
            ),
          );
        }
      });
    });

    group('Responsive Calculations', () {
      testWidgets('calculates chat message width correctly', (tester) async {
        final testCases = [
          // [width, expected percentage, description]
          [300, 0.75, 'small phone'],
          [400, 0.75, 'standard phone'],
          [600, 0.75, 'large phone'],
          [768, 0.75, 'small tablet'],
          [770, 0.5, 'large screen threshold'],
          [1024, 0.5, 'tablet landscape'],
          [1200, 0.5, 'small desktop'],
          [1600, 0.5, 'large desktop'],
        ];

        for (final testCase in testCases) {
          final width = testCase[0] as int;
          final percentage = testCase[1] as double;
          final description = testCase[2] as String;

          await tester.pumpWidget(
            buildTestWidget(
              Size(width.toDouble(), 800),
              child: Builder(
                builder: (context) {
                  final messageWidth = ActerBreakpoints.getChatMessageWidth(context);
                  final expectedWidth = width * percentage;
                  expect(messageWidth, expectedWidth, 
                    reason: '$description ($width px) should use $percentage% width');
                  return const SizedBox();
                },
              ),
            ),
          );
        }
      });

             testWidgets('calculates side sheet width correctly', (tester) async {
         final testCases = [
           // [screen width, expected sheet width, description]
           [200, 200 * 0.95, 'very small screen uses 95%'],
           [300, 300 * 0.95, 'small screen uses 95%'],
           [400, 400 * 0.95, 'below 300px threshold uses 95%'], // 400/1.4=285.7 < 300
           [420, 420 / 1.4, 'normal calculation'], // 420/1.4=300 exactly
           [500, 500 / 1.4, 'normal calculation'],
           [600, 600 / 1.4, 'tablet width'],
           [630, 450.0, 'capped at max'], // 630/1.4=450 exactly
           [800, 450.0, 'large screen capped'],
           [1000, 450.0, 'very large screen capped'],
           [1600, 450.0, 'very large screen capped'],
         ];

        for (final testCase in testCases) {
          final screenWidth = testCase[0] as int;
          final expectedWidth = testCase[1] as double;
          final description = testCase[2] as String;

          await tester.pumpWidget(
            buildTestWidget(
              Size(screenWidth.toDouble(), 800),
              child: Builder(
                builder: (context) {
                  final sheetWidth = ActerBreakpoints.getSideSheetWidth(context);
                  expect(sheetWidth, closeTo(expectedWidth, 0.1),
                    reason: '$description (${screenWidth}px screen)');
                  return const SizedBox();
                },
              ),
            ),
          );
        }
      });
    });

    group('Animation System', () {
      testWidgets('creates slide animations correctly', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            const Size(400, 600),
            child: const SizedBox(),
          ),
        );

        const testAnimation = AlwaysStoppedAnimation<double>(1.0);
        const testSecondaryAnimation = AlwaysStoppedAnimation<double>(0.0);
        const testChild = SizedBox();
        final context = tester.element(find.byType(MaterialApp));

        // Test all animation directions
        final bottomToTop = ActerAnimations.bottomToTop(
          context, testAnimation, testSecondaryAnimation, testChild);
        final topToBottom = ActerAnimations.topToBottom(
          context, testAnimation, testSecondaryAnimation, testChild);
        final leftToRight = ActerAnimations.leftToRight(
          context, testAnimation, testSecondaryAnimation, testChild);

        expect(bottomToTop, isA<SlideTransition>());
        expect(topToBottom, isA<SlideTransition>());
        expect(leftToRight, isA<SlideTransition>());
      });
    });

    group('Edge Cases and Extreme Values', () {
      testWidgets('handles very small screens', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            const Size(100, 200),
            child: Builder(
              builder: (context) {
                expect(ActerBreakpoints.isSmall(context), true);
                expect(ActerBreakpoints.shouldShowBottomNavigation(context), true);
                
                // Should use 95% for side sheet
                final sheetWidth = ActerBreakpoints.getSideSheetWidth(context);
                expect(sheetWidth, 100 * 0.95);
                
                // Should use 75% for chat messages
                final chatWidth = ActerBreakpoints.getChatMessageWidth(context);
                expect(chatWidth, 100 * 0.75);
                
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('handles very large screens', (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            const Size(3000, 2000),
            child: Builder(
              builder: (context) {
                expect(ActerBreakpoints.isExtraLarge(context), true);
                expect(ActerBreakpoints.shouldShowSidebar(context), true);
                
                // Should cap side sheet at 450px
                final sheetWidth = ActerBreakpoints.getSideSheetWidth(context);
                expect(sheetWidth, 450.0);
                
                // Should use 50% for chat messages
                final chatWidth = ActerBreakpoints.getChatMessageWidth(context);
                expect(chatWidth, 3000 * 0.5);
                
                return const SizedBox();
              },
            ),
          ),
        );
      });

      testWidgets('handles different aspect ratios', (tester) async {
        final aspectRatios = [
          Size(400, 200), // Very wide
          Size(200, 800), // Very tall
          Size(800, 800), // Square
          Size(1920, 1080), // Standard widescreen
          Size(1080, 1920), // Portrait orientation
        ];

        for (final size in aspectRatios) {
          await tester.pumpWidget(
            buildTestWidget(
              size,
              child: Builder(
                builder: (context) {
                  // Navigation logic should only depend on width
                  final shouldShowBottom = size.width < 1200;
                  expect(ActerBreakpoints.shouldShowBottomNavigation(context), shouldShowBottom);
                  expect(ActerBreakpoints.shouldShowSidebar(context), !shouldShowBottom);
                  return const SizedBox();
                },
              ),
            ),
          );
        }
      });
    });
  });
} 