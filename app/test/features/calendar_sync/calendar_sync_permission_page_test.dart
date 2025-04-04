import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/calendar_sync/calendar_sync_permission_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/test_util.dart';

void main() {
  testWidgets('renders correctly with all UI elements', (tester) async {
    // Initialize the widget
    await tester.pumpProviderWidget(child: const CalendarSyncPermissionWidget());

    // Wait for animations and async operations
    await tester.pumpAndSettle();

    // Verify specific buttons
    expect(find.byType(ActerPrimaryActionButton), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.text('Sync into Device Calendar'), findsOneWidget);

    // Verify close button in AppBar
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);
  });
}
