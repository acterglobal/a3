import 'package:acter/features/spaces/actions/select_permission.dart';
import 'package:acter/features/spaces/model/permission_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_util.dart';

void main() {
  Future<void> createWidgetUnderTest({
    required WidgetTester tester,
    PermissionLevel? currentPermission,
    Function(PermissionLevel)? onPermissionSelected,
  }) {
    return tester.pumpProviderWidget(
      overrides: [],
      child: SelectPermission(
        currentPermission: currentPermission ?? PermissionLevel.admin,
        onPermissionSelected: onPermissionSelected ?? (level) {},
      ),
    );
  }

  group('SelectPermission Widget Tests', () {
    testWidgets('should display all permission levels', (tester) async {
      await createWidgetUnderTest(tester: tester);

      // Verify that all permission levels are displayed
      expect(find.text('ADMIN'), findsOneWidget);
      expect(find.text('MODERATOR'), findsOneWidget);
      expect(find.text('EVERYONE'), findsOneWidget);
    });

    testWidgets('should show correct icons for each permission level', (
      tester,
    ) async {
      await createWidgetUnderTest(tester: tester);

      // Verify icons for each permission level
      expect(find.byIcon(Icons.admin_panel_settings), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.group), findsOneWidget);
    });

    testWidgets('should highlight selected permission level', (tester) async {
      await createWidgetUnderTest(
        tester: tester,
        currentPermission: PermissionLevel.admin,
      );

      // Verify that the selected permission (ADMIN) has the check icon
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets(
      'should call onPermissionSelected when a permission is tapped',
      (tester) async {
        PermissionLevel? selectedLevel;
        await createWidgetUnderTest(
          tester: tester,
          onPermissionSelected: (level) => selectedLevel = level,
        );

        // Tap on the MODERATOR permission
        await tester.tap(find.text('MODERATOR'));
        await tester.pumpAndSettle();

        // Verify that onPermissionSelected was called with the correct level
        expect(selectedLevel, equals(PermissionLevel.moderator));
      },
    );

    testWidgets('should navigate back after selecting a permission', (
      tester,
    ) async {
      await createWidgetUnderTest(tester: tester);

      // Tap on any permission
      await tester.tap(find.text('EVERYONE'));
      await tester.pumpAndSettle();

      // Verify that the widget was popped by checking if the widget is no longer in the tree
      expect(find.byType(SelectPermission), findsNothing);
    });

    testWidgets('should display correct title', (tester) async {
      await createWidgetUnderTest(tester: tester);

      // Verify the title text
      expect(find.text('Select Permission Level'), findsOneWidget);
    });

    testWidgets('should apply correct styling to selected permission', (
      tester,
    ) async {
      await createWidgetUnderTest(
        tester: tester,
        currentPermission: PermissionLevel.moderator,
      );

      // Find the selected permission text
      final selectedText = find.text('MODERATOR');
      expect(selectedText, findsOneWidget);

      // Verify the text style (color should be primary color)
      final textWidget = tester.widget<Text>(selectedText);
      expect(textWidget.style?.color, isNotNull);
    });
  });
}
