import 'dart:convert';
import 'package:acter/features/news/model/type/update_slide.dart';
import 'package:acter/common/toolkit/errors/util.dart';
import 'package:acter/features/news/widgets/news_item_slide/image_slide.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:acter/l10n/generated/l10n.dart';

class MockUpdateSlide extends Mock implements UpdateSlide {}

// Mock class for FfiBufferUint8 to mock the return value of asTypedList
class MockFfiBufferUint8 extends Mock implements FfiBufferUint8 {}

void main() {
  group('ImageSlide Widget Test', () {
    late MockUpdateSlide mockSlide;
    late MockFfiBufferUint8 mockFfiBuffer;

    setUp(() {
      mockSlide = MockUpdateSlide();
      mockFfiBuffer = MockFfiBufferUint8();
    });

    testWidgets('shows loading UI when data is loading', (tester) async {
      // Mock the sourceBinary method to simulate loading
      when(
        () => mockSlide.sourceBinary(null),
      ).thenAnswer((_) async => mockFfiBuffer);

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImageSlide(
              slide: mockSlide,
              errorState: NewsMediaErrorState.showErrorImageOnly,
            ),
          ),
        ),
      );

      // Verify that the loading UI (icon) is displayed
      expect(find.byIcon(PhosphorIcons.image()), findsOneWidget);
    });

    testWidgets('shows error UI and retries loading on TextButton click', (
      tester,
    ) async {
      when(
        () => mockSlide.sourceBinary(null),
      ).thenAnswer((_) async => Future.error('Failed to load image'));
      // Mock the typeStr method to return a valid string
      when(() => mockSlide.typeStr()).thenReturn('image');
      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          home: Scaffold(
            body: ImageSlide(
              slide: mockSlide,
              errorState: NewsMediaErrorState.showErrorImageOnly,
            ),
          ),
        ),
      );

      // Wait for Future to complete
      await tester.pumpAndSettle();

      expect(find.byIcon(PhosphorIcons.imageBroken()), findsOneWidget);

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          home: Scaffold(
            body: ImageSlide(
              slide: mockSlide,
              errorState: NewsMediaErrorState.showErrorImageWithText,
            ),
          ),
        ),
      );

      // Wait for Future to complete
      await tester.pumpAndSettle();

      expect(find.text('Unable to load image'), findsOneWidget);

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: L10n.localizationsDelegates,
          home: Scaffold(
            body: ImageSlide(
              slide: mockSlide,
              errorState: NewsMediaErrorState.showErrorWithTryAgain,
            ),
          ),
        ),
      );

      // Wait for Future to complete
      await tester.pumpAndSettle();

      expect(find.byIcon(PhosphorIcons.imageBroken()), findsOneWidget);
      expect(find.text('Unable to load image'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);

      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle(); // Wait for the widget to rebuild

      verify(() => mockSlide.sourceBinary(null)).called(4);
    });

    testWidgets('shows image UI when data loading is successful', (
      tester,
    ) async {
      const validImageBase64 =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/wcAAwAB/yy7K8EAAAAASUVORK5CYII=';

      final validImageBytes = base64Decode(validImageBase64);

      // Mock the sourceBinary method to return the image data
      when(
        () => mockSlide.sourceBinary(null),
      ).thenAnswer((_) async => mockFfiBuffer);
      when(() => mockFfiBuffer.asTypedList()).thenReturn(validImageBytes);

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImageSlide(
              slide: mockSlide,
              errorState: NewsMediaErrorState.showErrorImageOnly,
            ),
          ),
        ),
      );

      // Wait for Future to complete and all widgets to settle
      await tester.pumpAndSettle();
      expect(find.byKey(Key('image_container')), findsOneWidget);
      await tester.pump(Duration(seconds: 1)); // Waiting for 1 second
    });
  });
}
