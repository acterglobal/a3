import 'package:acter/features/desktop_setup/pages/desktop_setup_page.dart';
import 'package:acter/features/desktop_setup/providers/desktop_setup_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/test_util.dart';
import 'mocks/desktop_setup_mocks.dart';

void main() {
  late MockLaunchAtStartup mockLaunchAtStartup;
  late DesktopSetupNotifier notifier;

  setUp(() {
    mockLaunchAtStartup = MockLaunchAtStartup();
    // Mock the default behavior
    when(() => mockLaunchAtStartup.isEnabled()).thenAnswer((_) async => false);
    when(() => mockLaunchAtStartup.enable()).thenAnswer((_) async => true);
    when(() => mockLaunchAtStartup.disable()).thenAnswer((_) async => true);
    
    // Create notifier with mock
    notifier = DesktopSetupNotifier(mockLaunchAtStartup);
  });

  testWidgets('DesktopSetupWidget renders correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpProviderWidget(
      child: DesktopSetupWidget(callNextPage: () {}),
      overrides: [
        desktopSetupNotifierProvider.overrideWith((_) => notifier),
      ],
    );

    // Verify the widget renders
    expect(find.byType(DesktopSetupWidget), findsOneWidget);

    // Verify key UI elements are present
    expect(find.byType(Checkbox), findsOneWidget); // Features checkbox
    expect(find.byType(ElevatedButton), findsOneWidget); // Continue button
  });

  testWidgets('DesktopSetupWidget handles enable/disable features', (
    WidgetTester tester,
  ) async {
    await tester.pumpProviderWidget(
      child: DesktopSetupWidget(callNextPage: () {}),
      overrides: [
        desktopSetupNotifierProvider.overrideWith((_) => notifier),
      ],
    );

    // Initial state should be unchecked
    final initialCheckbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(initialCheckbox.value, isFalse);

    // Tap the checkbox to enable features
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    
    // Verify checkbox state updated immediately
    final updatedCheckbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(updatedCheckbox.value, isTrue);
    
    // Verify enable was called
    verify(() => mockLaunchAtStartup.enable()).called(1);

    // Tap again to disable
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    
    // Verify checkbox state updated to false
    final disabledCheckbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(disabledCheckbox.value, isFalse);
    
    // Verify disable was called
    verify(() => mockLaunchAtStartup.disable()).called(1);
  });

  testWidgets('DesktopSetupWidget handles continue button', (
    WidgetTester tester,
  ) async {
    bool wasCalled = false;
    await tester.pumpProviderWidget(
      child: DesktopSetupWidget(
        callNextPage: () {
          wasCalled = true;
        },
      ),
      overrides: [
        desktopSetupNotifierProvider.overrideWith((_) => notifier),
      ],
    );

    // Verify initial state
    expect(find.byType(DesktopSetupWidget), findsOneWidget);
    expect(wasCalled, isFalse);

    // Tap the continue button
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // Verify the callback was called
    expect(wasCalled, isTrue);
  });
}
