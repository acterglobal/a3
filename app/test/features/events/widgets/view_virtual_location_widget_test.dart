import 'package:acter/features/events/widgets/view_virtual_location_widget.dart';
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
    when(() => mockLocation.name()).thenReturn('Virtual Meeting');
    when(() => mockLocation.uri()).thenReturn('https://meet.example.com');
    when(() => mockLocation.notes()).thenReturn('Test notes');
  });

  Future<void> pumpViewVirtualLocationWidget(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ViewVirtualLocationWidget(
                context: context,
                location: mockLocation,
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    context = tester.element(find.byType(ViewVirtualLocationWidget));
  }

  group('ViewVirtualLocationWidget', () {
    testWidgets('displays location information correctly', (tester) async {
      await pumpViewVirtualLocationWidget(tester);

      // Verify location name and URL are displayed
      expect(find.text('Virtual Meeting'), findsOneWidget);
      expect(find.text('https://meet.example.com'), findsOneWidget);
      expect(find.byIcon(Icons.language), findsOneWidget);
    });

    testWidgets('displays location notes when present', (tester) async {
      await pumpViewVirtualLocationWidget(tester);

      // Verify notes label and content
      expect(find.text('${L10n.of(context).notes}:'), findsOneWidget);
      expect(find.text('Test notes'), findsOneWidget);
    });

    testWidgets('hides notes section when notes are empty', (tester) async {
      when(() => mockLocation.notes()).thenReturn('');
      await pumpViewVirtualLocationWidget(tester);

      // Verify notes section is not displayed
      expect(find.text('${L10n.of(context).notes}:'), findsNothing);
      expect(find.text('Test notes'), findsNothing);
    });

    testWidgets('hides notes section when notes are null', (tester) async {
      when(() => mockLocation.notes()).thenReturn(null);
      await pumpViewVirtualLocationWidget(tester);

      // Verify notes section is not displayed
      expect(find.text('${L10n.of(context).notes}:'), findsNothing);
      expect(find.text('Test notes'), findsNothing);
    });

    testWidgets('copies URL to clipboard when copy button is tapped', (tester) async {
      await pumpViewVirtualLocationWidget(tester);

      // Tap copy button
      await tester.tap(find.text(L10n.of(context).copyLinkOnly));
      await tester.pumpAndSettle();

      // Verify snackbar is shown
      expect(find.text(L10n.of(context).copyToClipboard), findsOneWidget);
    });

    testWidgets('opens URL in browser when open link button is tapped', (tester) async {
      await pumpViewVirtualLocationWidget(tester);

      // Tap open link button
      await tester.tap(find.text(L10n.of(context).openLink));
      await tester.pumpAndSettle();

      // Note: We can't directly test the URL launch since it's an external action
      // But we can verify the button is present and tappable
      expect(find.text(L10n.of(context).openLink), findsOneWidget);
    });

    testWidgets('handles missing URL gracefully', (tester) async {
      when(() => mockLocation.uri()).thenReturn(null);
      await pumpViewVirtualLocationWidget(tester);

      // Verify widget still renders without crashing
      expect(find.text('Virtual Meeting'), findsOneWidget);
      expect(find.byType(ViewVirtualLocationWidget), findsOneWidget);
    });

    testWidgets('handles missing name gracefully', (tester) async {
      when(() => mockLocation.name()).thenReturn(null);
      await pumpViewVirtualLocationWidget(tester);

      // Verify widget still renders without crashing
      expect(find.byType(ViewVirtualLocationWidget), findsOneWidget);
    });

    testWidgets('displays long URL with ellipsis', (tester) async {
      const longUrl = 'https://very.long.url.that.should.be.truncated.with.ellipsis.'
          'when.it.exceeds.the.maximum.number.of.lines.allowed.in.the.UI.'
          'This.helps.maintain.a.consistent.layout.while.still.showing.the.most.important.'
          'information.to.the.user.com';
      when(() => mockLocation.uri()).thenReturn(longUrl);
      
      await pumpViewVirtualLocationWidget(tester);

      // Verify the URL is displayed with ellipsis
      final urlFinder = find.text(longUrl);
      expect(urlFinder, findsOneWidget);
      
      // Get the Text widget and verify its properties
      final textWidget = tester.widget<Text>(urlFinder);
      expect(textWidget.maxLines, 2);
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('displays long notes with ellipsis', (tester) async {
      const longNotes = 'These are very long notes that should be truncated with ellipsis '
          'when they exceed the maximum number of lines allowed in the UI. '
          'This helps maintain a consistent layout while still showing the most important '
          'information to the user.';
      when(() => mockLocation.notes()).thenReturn(longNotes);
      
      await pumpViewVirtualLocationWidget(tester);

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