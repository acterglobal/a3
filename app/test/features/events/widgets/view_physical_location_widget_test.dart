
import 'package:acter/features/events/widgets/view_physical_location_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../../helpers/mock_event_location.dart';

void main() {
  late MockEventLocationInfo mockLocation;
  late BuildContext context;

  setUp(() {
    mockLocation = MockEventLocationInfo();
    when(() => mockLocation.name()).thenReturn('Test Location');
    when(() => mockLocation.address()).thenReturn('123 Test Street');
    when(() => mockLocation.notes()).thenReturn('Test notes');
  });

  Future<void> pumpViewPhysicalLocationWidget(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ViewPhysicalLocationWidget(
                context: context,
                location: mockLocation,
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    context = tester.element(find.byType(ViewPhysicalLocationWidget));
  }

  group('ViewPhysicalLocationWidget', () {
    testWidgets('displays location information correctly', (tester) async {
      await pumpViewPhysicalLocationWidget(tester);

      // Verify location name and address are displayed
      expect(find.text('Test Location'), findsOneWidget);
      expect(find.text('123 Test Street'), findsOneWidget);
      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    });

    testWidgets('displays location notes correctly', (tester) async {
      await pumpViewPhysicalLocationWidget(tester);

      // Verify notes label and content
      expect(find.text('${L10n.of(context).notes}:'), findsOneWidget);
      expect(find.text('Test notes'), findsOneWidget);
    });

    testWidgets('copies location to clipboard when copy button is tapped', (tester) async {
      await pumpViewPhysicalLocationWidget(tester);

      // Tap copy button
      await tester.tap(find.text(L10n.of(context).copyOnly));
      await tester.pumpAndSettle();

      // Verify snackbar is shown
      expect(find.text(L10n.of(context).copyToClipboard), findsOneWidget);
    });

    testWidgets('opens map when show on map button is tapped', (tester) async {
      await pumpViewPhysicalLocationWidget(tester);

      // Tap show on map button
      await tester.tap(find.text(L10n.of(context).showOnMap));
      await tester.pumpAndSettle();

      // Note: We can't directly test the URL launch since it's an external action
      // But we can verify the button is present and tappable
      expect(find.text(L10n.of(context).showOnMap), findsOneWidget);
    });

    testWidgets('handles missing address gracefully', (tester) async {
      when(() => mockLocation.address()).thenReturn(null);
      await pumpViewPhysicalLocationWidget(tester);

      // Verify widget still renders without crashing
      expect(find.text('Test Location'), findsOneWidget);
      expect(find.byType(ViewPhysicalLocationWidget), findsOneWidget);
    });

    testWidgets('handles missing notes gracefully', (tester) async {
      when(() => mockLocation.notes()).thenReturn(null);
      await pumpViewPhysicalLocationWidget(tester);

      // Verify widget still renders without crashing
      expect(find.text('Test Location'), findsOneWidget);
      expect(find.byType(ViewPhysicalLocationWidget), findsOneWidget);
    });

    testWidgets('displays long address with ellipsis', (tester) async {
      const longAddress = 'This is a very long address that should be truncated with ellipsis '
          'when it exceeds the maximum number of lines allowed in the UI. '
          'This helps maintain a consistent layout while still showing the most important '
          'information to the user.';
      when(() => mockLocation.address()).thenReturn(longAddress);
      
      await pumpViewPhysicalLocationWidget(tester);

      // Verify the address is displayed with ellipsis
      final addressFinder = find.text(longAddress);
      expect(addressFinder, findsOneWidget);
      
      // Get the Text widget and verify its properties
      final textWidget = tester.widget<Text>(addressFinder);
      expect(textWidget.maxLines, 2);
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('displays long notes with ellipsis', (tester) async {
      const longNotes = 'These are very long notes that should be truncated with ellipsis '
          'when they exceed the maximum number of lines allowed in the UI. '
          'This helps maintain a consistent layout while still showing the most important '
          'information to the user.';
      when(() => mockLocation.notes()).thenReturn(longNotes);
      
      await pumpViewPhysicalLocationWidget(tester);

      // Verify the notes are displayed with ellipsis
      final notesFinder = find.text(longNotes);
      expect(notesFinder, findsOneWidget);
      
      // Get the Text widget and verify its properties
      final textWidget = tester.widget<Text>(notesFinder);
      expect(textWidget.maxLines, 2);
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });
  });
} 