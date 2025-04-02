import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/notifications/pages/notification_permission_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../helpers/test_util.dart';

void main() {
  testWidgets('renders correctly with all UI elements', (tester) async {
    // Initialize the widget
    await tester.pumpProviderWidget(child: const NotificationPermissionPage());

    // Wait for animations and async operations
    await tester.pumpAndSettle();

    // Verify specific buttons
    expect(find.byType(ActerPrimaryActionButton), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);

    expect(find.text('Direct Invitations'), findsOneWidget);
    expect(find.text('Messages from your chat'), findsOneWidget);
    expect(find.text('Boosts from your peers'), findsOneWidget);
    expect(find.text('Comment on your things'), findsOneWidget);
    expect(find.text('Things you actively subscribe to'), findsOneWidget);
    expect(find.text('No marketing spam'), findsOneWidget);

    // Verify close button in AppBar
    expect(find.byIcon(Icons.close), findsOneWidget);

    expect(find.byIcon(PhosphorIcons.checkCircle()), findsWidgets);
    expect(find.byIcon(PhosphorIcons.bell()), findsOneWidget);
    expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
  });
}
