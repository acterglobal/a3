import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/backups/widgets/backup_state_widget.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BackupPage extends ConsumerWidget {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return WithSidebar(
      sidebar: const SettingsPage(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !context.isLargeScreen,
          title: Text(lang.encryptionBackupKeyBackup),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Text(lang.encryptionBackupKeyBackupExplainer),
            const BackupStateWidget(allowDisabling: true),
          ],
        ),
      ),
    );
  }
}
