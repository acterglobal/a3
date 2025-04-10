import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/chat_ui_showcase/widgets/chat_item/mute_icon_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../helpers/test_util.dart';

void main() {
  group('MuteIconWidget Tests', () {
    Future<void> createWidgetUnderTest({
      required WidgetTester tester,
      bool isMuted = true,
      bool isError = false,
      bool isLoading = false,
    }) async {
      await tester.pumpProviderWidget(
        overrides: [
          roomIsMutedProvider.overrideWith((a, b) {
            if (isLoading) {
              return Future.delayed(
                const Duration(milliseconds: 100),
                () => isMuted,
              );
            }
            if (isError) {
              return Future.error('Error');
            }
            return Future.value(isMuted);
          }),
        ],
        child: MuteIconWidget(roomId: 'mock-room-1'),
      );
      // Wait for the async provider to load
      await tester.pump();
    }

    testWidgets('should show mute icon when room is muted', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(tester: tester, isMuted: true);
      expect(find.byIcon(PhosphorIcons.bellSlash()), findsOneWidget);
    });

    testWidgets('should not show mute icon when room is not muted', (
      WidgetTester tester,
    ) async {
      await createWidgetUnderTest(tester: tester, isMuted: false);
      expect(find.byIcon(PhosphorIcons.bellSlash()), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('should use correct icon size', (WidgetTester tester) async {
      await createWidgetUnderTest(tester: tester, isMuted: true);
      final icon = tester.widget<Icon>(find.byIcon(PhosphorIcons.bellSlash()));
      expect(icon.size, equals(20));
    });

    testWidgets('should use correct icon color', (WidgetTester tester) async {
      await createWidgetUnderTest(tester: tester, isMuted: true);
      final icon = tester.widget<Icon>(find.byIcon(PhosphorIcons.bellSlash()));
      final theme = Theme.of(
        tester.element(find.byIcon(PhosphorIcons.bellSlash())),
      );
      expect(icon.color, equals(theme.colorScheme.surfaceTint));
    });

    testWidgets('should have correct padding', (WidgetTester tester) async {
      await createWidgetUnderTest(tester: tester, isMuted: true);
      final padding = tester.widget<Padding>(find.byType(Padding));
      expect(padding.padding, equals(const EdgeInsets.only(left: 4)));
    });

    testWidgets('should handle error case', (WidgetTester tester) async {
      await createWidgetUnderTest(tester: tester, isError: true);
      expect(find.byIcon(PhosphorIcons.bookmarkSimple()), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('should handle loading case', (WidgetTester tester) async {
      await createWidgetUnderTest(
        tester: tester,
        isLoading: true,
        isMuted: true,
      );

      expect(find.byWidgetPredicate((w) => w is Skeletonizer), findsOneWidget);
      // Wait for the async provider to load
      await tester.pump(const Duration(milliseconds: 110));
      expect(find.byIcon(PhosphorIcons.bellSlash()), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Skeletonizer), findsNothing);
    });
  });
}
