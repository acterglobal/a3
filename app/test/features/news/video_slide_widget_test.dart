
import 'package:acter/features/news/widgets/news_item_slide/video_slide.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class MockNewsSlide extends Mock implements NewsSlide {}

// Mock class for FfiBufferUint8 to mock the return value of asTypedList
class MockFfiBufferUint8 extends Mock implements FfiBufferUint8 {}

void main() {
  group('VideoSlide Widget Test', () {
    late MockNewsSlide mockSlide;
    late MockFfiBufferUint8 mockFfiBuffer;

    setUp(() {
      mockSlide = MockNewsSlide();
      mockFfiBuffer = MockFfiBufferUint8();
    });

    testWidgets('shows loading UI when data is loading', (tester) async {
      // Mock the sourceBinary method to simulate loading
      when(() => mockSlide.sourceBinary(null)).thenAnswer(
        (_) async => mockFfiBuffer,
      );

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: VideoSlide(slide: mockSlide)),
        ),
      );

      // Verify that the loading UI (icon) is displayed
      expect(find.byIcon(PhosphorIcons.video()), findsOneWidget);
    });

    testWidgets('shows error UI and retries loading on TextButton click',
        (tester) async {
      when(() => mockSlide.sourceBinary(null))
          .thenAnswer((_) async => Future.error('Failed to load video'));
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          home: Scaffold(body: VideoSlide(slide: mockSlide)),
        ),
      );

      // Wait for Future to complete
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.videocam_off_outlined), findsOneWidget);
      expect(find.text('Unable to load video'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);

      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle(); // Wait for the widget to rebuild

      verify(() => mockSlide.sourceBinary(null)).called(2); // Called twice (1 for the initial error, 1 for retry)
    });
  });
}
