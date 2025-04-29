import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:acter/features/onboarding/widgets/encryption_backup_widget.dart';
import 'package:acter/common/providers/app_install_check_provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../helpers/test_util.dart';

void main() {
  const testEncryptionKey = 'test-encryption-key-123';

  group('PasswordManagerBackupWidget', () {
    testWidgets('renders correctly with encryption key', (tester) async {
      await tester.pumpProviderWidget(
        child: PasswordManagerBackupWidget(encryptionKey: testEncryptionKey),
      );

      // Verify the widget renders
      expect(find.byType(PasswordManagerBackupWidget), findsOneWidget);
    });

    testWidgets('share button is present', (tester) async {
      await tester.pumpProviderWidget(
        child: PasswordManagerBackupWidget(encryptionKey: testEncryptionKey),
      );
      await tester.pumpAndSettle();
      // Verify share button is present
      expect(find.byIcon(PhosphorIcons.share()), findsOneWidget);
    });

    testWidgets('copy button is present', (tester) async {
      await tester.pumpProviderWidget(
        child: PasswordManagerBackupWidget(encryptionKey: testEncryptionKey),
      );
      await tester.pumpAndSettle();
      // Verify share button is present
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('shows installed password manager buttons', (tester) async {
      await tester.pumpProviderWidget(
        child: PasswordManagerBackupWidget(encryptionKey: testEncryptionKey),
        overrides: [
          isAppInstalledProvider(
            ExternalApps.onePassword,
          ).overrideWith((ref) => Future.value(true)),
          isAppInstalledProvider(
            ExternalApps.bitwarden,
          ).overrideWith((ref) => Future.value(true)),
          isAppInstalledProvider(
            ExternalApps.lastPass,
          ).overrideWith((ref) => Future.value(false)),
          isAppInstalledProvider(
            ExternalApps.protonPass,
          ).overrideWith((ref) => Future.value(false)),
        ],
      );

      // Wait for the async providers to complete
      await tester.pumpAndSettle();

      // Verify password manager buttons are shown
      expect(find.byIcon(Icons.security), findsOneWidget); // 1Password
      expect(find.byIcon(Icons.vpn_key), findsOneWidget); // Bitwarden
      expect(find.byIcon(Icons.lock), findsNothing); // LastPass
      expect(find.byIcon(Icons.lock), findsNothing); // ProtonPass
    });
  });
}
