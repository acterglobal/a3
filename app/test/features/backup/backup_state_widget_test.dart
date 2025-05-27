import 'dart:math';

import 'package:acter/common/providers/notifiers/client_pref_notifier.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/features/backups/dialogs/provide_recovery_key_dialog.dart';
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockingjay/mockingjay.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/pref_provider_mocks.dart';
import '../../helpers/test_util.dart';

class MockRecoveryStateNotifier extends Notifier<RecoveryState>
    with Mock
    implements RecoveryStateNotifier {
  @override
  RecoveryState build() => _state;

  final RecoveryState _state;

  MockRecoveryStateNotifier(this._state);
}

// Mock BackupManager
class MockBackupManager extends Mock implements BackupManager {}

void main() {
  setUp(() {
    EasyLoading.init();
  });

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
        hasProvidedKeyProvider.overrideWith(() => MockAsyncPrefNotifier(false)),
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

  group('BackupStateWidget flows', () {
    testWidgets('populates the key on provide flow simple', (
      WidgetTester tester,
    ) async {
      final recoveryStateNotifier = MockRecoveryStateNotifier(
        RecoveryState.incomplete,
      );
      final mockBackupManager = MockBackupManager();

      await tester.pumpProviderWidget(
        child: Scaffold(body: BackupStateWidget(allowDisabling: true)),
        overrides: [
          backupStateProvider.overrideWith(() => recoveryStateNotifier),
          backupManagerProvider.overrideWith((ref) => mockBackupManager),
        ],
      );

      await tester.pump();

      final context = tester.element(find.byType(BackupStateWidget));
      final lang = L10n.of(context);

      final provideActionFinder = find.text(
        lang.encryptionBackupProvideKeyAction,
      );
      expect(provideActionFinder, findsOneWidget);

      final newlyCreatedKey = 'new-key-${Random().nextInt(1000000)}';

      when(() => mockBackupManager.recover(newlyCreatedKey)).thenAnswer((
        _,
      ) async {
        // we update the state if you provided the right key
        recoveryStateNotifier.state = RecoveryState.enabled;
        return true;
      });

      await tester.runAsync(() async {
        await tester.tap(provideActionFinder);
        await tester.pumpAndSettle();

        final textField = find.byKey(recoveryKeyFormKey);
        expect(textField, findsOneWidget);
        await tester.enterText(textField, newlyCreatedKey);

        await tester.tap(find.text(lang.encryptionBackupRecoverAction));
        await tester.pumpAndSettle();

        // we are in the proper state now
        expect(recoveryStateNotifier.state, RecoveryState.enabled);

        expect(find.text(lang.encryptionBackupRotateKey), findsOneWidget);
        expect(find.text(lang.encryptionBackupResetIdentity), findsOneWidget);
        // the new key is shown
      });

      verify(() => mockBackupManager.recover(newlyCreatedKey)).called(1);
    });

    testWidgets('stays incomplete despite the key provided', (
      WidgetTester tester,
    ) async {
      final recoveryStateNotifier = MockRecoveryStateNotifier(
        RecoveryState.incomplete,
      );
      final mockBackupManager = MockBackupManager();

      await tester.pumpProviderWidget(
        child: Scaffold(body: BackupStateWidget(allowDisabling: true)),
        overrides: [
          backupStateProvider.overrideWith(() => recoveryStateNotifier),
          backupManagerProvider.overrideWith((ref) => mockBackupManager),
        ],
      );

      await tester.pump();

      final context = tester.element(find.byType(BackupStateWidget));
      final lang = L10n.of(context);

      final provideActionFinder = find.text(
        lang.encryptionBackupProvideKeyAction,
      );
      expect(provideActionFinder, findsOneWidget);

      final newlyCreatedKey = 'new-key-${Random().nextInt(1000000)}';

      when(() => mockBackupManager.recover(newlyCreatedKey)).thenAnswer((
        _,
      ) async {
        // this stays incompleted
        recoveryStateNotifier.state = RecoveryState.incomplete;
        return true;
      });

      await tester.runAsync(() async {
        await tester.tap(provideActionFinder);
        await tester.pumpAndSettle();

        final textField = find.byKey(recoveryKeyFormKey);
        expect(textField, findsOneWidget);
        await tester.enterText(textField, newlyCreatedKey);

        await tester.tap(find.text(lang.encryptionBackupRecoverAction));
        await tester.pumpAndSettle();

        // we are in the proper state now
        expect(recoveryStateNotifier.state, RecoveryState.incomplete);

        // we have been incompleted but the key is not working, we mark it
        // as such and allow the user to retry or reset the idenity.

        expect(
          find.text(lang.encryptionBackupProvideKeyAction),
          findsOneWidget,
        );
        expect(find.text(lang.encryptionBackupResetIdentity), findsOneWidget);
        // the new key is shown
      });

      verify(() => mockBackupManager.recover(newlyCreatedKey)).called(1);
    });

    testWidgets('shows the key on rotate flow', (WidgetTester tester) async {
      final recoveryStateNotifier = MockRecoveryStateNotifier(
        RecoveryState.enabled,
      );
      final mockBackupManager = MockBackupManager();

      await tester.pumpProviderWidget(
        child: Scaffold(body: BackupStateWidget(allowDisabling: true)),
        overrides: [
          backupStateProvider.overrideWith(() => recoveryStateNotifier),
          backupManagerProvider.overrideWith((ref) => mockBackupManager),
        ],
      );

      await tester.pump();

      final context = tester.element(find.byType(BackupStateWidget));
      final lang = L10n.of(context);

      final resetFinder = find.text(lang.encryptionBackupRotateKey);
      expect(resetFinder, findsOneWidget);
      expect(find.text(lang.encryptionBackupResetIdentity), findsOneWidget);

      final newlyCreatedKey = 'new-key-${Random().nextInt(1000000)}';

      when(
        () => mockBackupManager.resetKey(),
      ).thenAnswer((_) async => newlyCreatedKey);

      await tester.runAsync(() async {
        await tester.tap(resetFinder);
        await tester.pumpAndSettle();

        final resetIdentityFinder = find.text(
          lang.encryptionBackupDisableActionDestroyIt,
        );
        expect(resetIdentityFinder, findsOneWidget);

        await tester.tap(resetIdentityFinder);
        await tester.pumpAndSettle();

        expect(find.text(newlyCreatedKey), findsOneWidget);
        // the new key is shown
      });
    });
  });
}
