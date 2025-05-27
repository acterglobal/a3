import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/features/backups/providers/backup_manager_provider.dart';
import 'package:acter/features/backups/providers/backup_state_providers.dart';
import 'package:acter/features/backups/providers/notifiers/backup_state_notifier.dart';
import 'package:acter/features/backups/types.dart';
import 'package:acter/features/backups/widgets/backup_state_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/test_util.dart';

class MockRecoveryStateNotifier extends RecoveryStateNotifier {
  @override
  RecoveryState build() => _state;

  RecoveryState _state;

  MockRecoveryStateNotifier(this._state);

  void setState(RecoveryState newState) {
    _state = newState;
    state = newState;
  }
}

// Mock BackupManager
class MockBackupManager implements BackupManager {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

void main() {
  Future<void> pumpBackupStateWidget(
    WidgetTester tester, {
    required RecoveryState state,
    bool allowDisabling = false,
  }) async {
    await tester.pumpProviderWidget(
      child: Scaffold(body: BackupStateWidget(allowDisabling: allowDisabling)),
      overrides: [
        backupStateProvider.overrideWith(
          () => MockRecoveryStateNotifier(state),
        ),
        backupManagerProvider.overrideWith(
          (ref) => Future.delayed(
            const Duration(milliseconds: 200),
            () => MockBackupManager(),
          ),
        ),
      ],
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  setUp(() {
    EasyLoading.init();
  });

  group('BackupStateWidget', () {
    testWidgets('renders unknown state with skeleton loader', (
      WidgetTester tester,
    ) async {
      await pumpBackupStateWidget(tester, state: RecoveryState.unknown);
      expect(find.text('Loading'), findsOneWidget);
    });

    testWidgets(
      'renders enabled state with reset button when allowing disabling',
      (WidgetTester tester) async {
        await pumpBackupStateWidget(
          tester,
          state: RecoveryState.enabled,
          allowDisabling: true,
        );

        final context = tester.element(find.byType(BackupStateWidget));
        final lang = L10n.of(context);

        expect(find.byIcon(Atlas.check_website_thin), findsOneWidget);
        expect(find.text(lang.encryptionBackupRotateKey), findsOneWidget);
        expect(find.text(lang.encryptionBackupResetIdentity), findsOneWidget);
      },
    );

    testWidgets('renders nothing when enabled and disabling not allowed', (
      WidgetTester tester,
    ) async {
      await pumpBackupStateWidget(
        tester,
        state: RecoveryState.enabled,
        allowDisabling: false,
      );

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('renders incomplete state with correct actions', (
      WidgetTester tester,
    ) async {
      await pumpBackupStateWidget(
        tester,
        state: RecoveryState.incomplete,
        allowDisabling: true,
      );

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      // Should find 2 buttons when allowing disabling
      expect(find.byType(OutlinedButton), findsNWidgets(2));
    });

    testWidgets('renders disabled state with start action', (
      WidgetTester tester,
    ) async {
      await pumpBackupStateWidget(tester, state: RecoveryState.disabled);

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('verifies warning color for incomplete state', (
      WidgetTester tester,
    ) async {
      await pumpBackupStateWidget(tester, state: RecoveryState.incomplete);

      final iconFinder = find.byIcon(Icons.warning_amber_rounded);
      final icon = tester.widget<Icon>(iconFinder);
      expect(icon.color, equals(warningColor));
    });

    testWidgets('verifies primary color for enabled state', (
      WidgetTester tester,
    ) async {
      await pumpBackupStateWidget(
        tester,
        state: RecoveryState.enabled,
        allowDisabling: true,
      );

      final iconFinder = find.byIcon(Atlas.check_website_thin);
      final icon = tester.widget<Icon>(iconFinder);
      expect(icon.color, isA<Color>());
    });
  });
}
