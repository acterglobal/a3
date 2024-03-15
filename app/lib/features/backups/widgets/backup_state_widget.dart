import 'package:acter/features/backups/providers/backup_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BackupStateWidget extends ConsumerWidget {
  const BackupStateWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentState = ref.watch(backupStateProvider);
    return Card(child: ListTile(title: Text('$currentState')));
  }
}
