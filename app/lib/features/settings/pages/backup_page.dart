import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/backups/widgets/backup_state_widget.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BackupPage extends ConsumerWidget {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return WithSidebar(
      sidebar: const SettingsPage(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const AppBarTheme().backgroundColor,
          elevation: 0.0,
          title: const Text('Key backup'),
          centerTitle: true,
        ),
        body: const Column(
          children: [
            Text('Here you configure the Key Backup'),
            BackupStateWidget(allowDisabling: true),
          ],
        ),
      ),
    );
  }
}
