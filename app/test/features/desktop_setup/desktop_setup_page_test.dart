import 'package:acter/features/desktop_setup/pages/desktop_setup_page.dart';
import 'package:acter/features/desktop_setup/providers/desktop_setup_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/test_util.dart';
import 'mocks/desktop_setup_mocks.dart';

void main() {
  late MockLaunchAtStartup mockLaunchAtStartup;

  setUp(() {
    mockLaunchAtStartup = MockLaunchAtStartup();
    // Mock the default behavior
    when(() => mockLaunchAtStartup.isEnabled()).thenAnswer((_) async => false);
    when(() => mockLaunchAtStartup.enable()).thenAnswer((_) async => true);
    when(() => mockLaunchAtStartup.disable()).thenAnswer((_) async => true);
  });

  testWidgets('DesktopSetupWidget renders correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpProviderWidget(
      child: DesktopSetupWidget(callNextPage: () {}),
      overrides: [
        launchAtStartupProvider.overrideWithValue(mockLaunchAtStartup),
      ],
    );

    // Verify the widget renders
    expect(find.byType(DesktopSetupWidget), findsOneWidget);

    // Verify key UI elements are present
    expect(find.byIcon(Icons.close), findsOneWidget); // Close button
    expect(find.byType(Checkbox), findsOneWidget); // Features checkbox
    expect(find.byType(ElevatedButton), findsOneWidget); // Continue button
  });

  testWidgets('DesktopSetupWidget handles enable/disable features', (
    WidgetTester tester,
  ) async {
    await tester.pumpProviderWidget(
      child: DesktopSetupWidget(callNextPage: () {}),
      overrides: [
        launchAtStartupProvider.overrideWithValue(mockLaunchAtStartup),
      ],
    );

    // Initial state should be unchecked
    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isFalse);

    // Tap the checkbox to enable features
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    // Verify enable was called
    verify(() => mockLaunchAtStartup.enable()).called(1);
  });

  testWidgets('DesktopSetupWidget handles continue button', (
    WidgetTester tester,
  ) async {
    await tester.pumpProviderWidget(
      child: DesktopSetupWidget(callNextPage: () {}),
      overrides: [
        launchAtStartupProvider.overrideWithValue(mockLaunchAtStartup),
      ],
    );

    // Tap the continue button
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Verify the dialog is dismissed
    expect(find.byType(DesktopSetupWidget), findsNothing);
  });

  testWidgets('DesktopSetupWidget handles close button', (
    WidgetTester tester,
  ) async {
    await tester.pumpProviderWidget(
      child: DesktopSetupWidget(callNextPage: () {}),
      overrides: [
        launchAtStartupProvider.overrideWithValue(mockLaunchAtStartup),
      ],
    );

    // Tap the close button
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Verify the dialog is dismissed
    expect(find.byType(DesktopSetupWidget), findsNothing);
  });
}
