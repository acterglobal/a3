import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/features/activities/widgets/security_and_privacy_section/store_the_key_securely_widget.dart';
import 'package:acter/features/backups/providers/backup_manager_provider.dart';
import 'package:acter/features/backups/providers/backup_state_providers.dart';
import 'package:acter/features/backups/providers/notifiers/backup_state_notifier.dart';
import 'package:acter/features/backups/types.dart';
import 'package:acter/features/backups/widgets/backup_state_widget.dart';
import 'package:acter/features/datetime/providers/utc_now_provider.dart';
import 'package:acter/features/settings/pages/backup_page.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../common/mock_data/mock_avatar_info.dart';
import '../../helpers/mock_event_providers.dart';
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
  late MockBackupManager mockBackupManager;
  late MockRecoveryStateNotifier mockRecoveryStateNotifier;
  late MockUtcNowNotifier mockUtcNowNotifier;

  setUp(() {
    EasyLoading.init();
    mockBackupManager = MockBackupManager();
    mockRecoveryStateNotifier = MockRecoveryStateNotifier(
      RecoveryState.enabled,
    );
    mockUtcNowNotifier = MockUtcNowNotifier();
  });

  Future<void> pumpBackupStateWidget(
    WidgetTester tester, {
    required RecoveryState state,
  }) async {
    await tester.pumpProviderWidget(
      child: Scaffold(body: BackupPageBody()),
      overrides: [
        accountAvatarInfoProvider.overrideWith(
          (ref) => MockAvatarInfo(uniqueId: 'user-1'),
        ),
        myUserIdStrProvider.overrideWith((ref) => 'user-1'),
        backupStateProvider.overrideWith(() => mockRecoveryStateNotifier),
        storedEncKeyProvider.overrideWith(
          (ref) => Future.value('test-encryption-key'),
        ),
        storedEncKeyTimestampProvider.overrideWith(
          (ref) => Future.value(DateTime.now().millisecondsSinceEpoch),
        ),
        utcNowProvider.overrideWith((ref) => mockUtcNowNotifier),
        backupManagerProvider.overrideWith((ref) => mockBackupManager),
      ],
    );

    await tester.pump();
  }

  group('BackupPage', () {
    testWidgets('shows enabled state', (WidgetTester tester) async {
      await pumpBackupStateWidget(tester, state: RecoveryState.enabled);

      final context = tester.element(find.byType(BackupStateWidget));
      final lang = L10n.of(context);
      expect(find.text(lang.encryptionBackupRotateKey), findsOneWidget);
    });

    testWidgets('shows recovery key reminder ', (WidgetTester tester) async {
      await pumpBackupStateWidget(tester, state: RecoveryState.enabled);

      expect(find.byType(StoreTheKeySecurelyWidget), findsOneWidget);
    });
  });
}
