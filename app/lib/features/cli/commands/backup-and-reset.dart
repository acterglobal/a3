import 'package:args/command_runner.dart';
import 'package:acter/features/cli/util.dart';

import 'dart:io';
import 'dart:convert';
import 'dart:core';
// ignore_for_file: avoid_print

class BackupAndResetCommand extends Command {
  @override
  final name = 'backup-and-reset';
  @override
  final description =
      'Backup accounts and sessions and reset the state to fresh and clean';

  BackupAndResetCommand();

  @override
  Future<void> run() async {
    final now = DateTime.now();
    final tzMinTotal = now.timeZoneOffset.inMinutes;
    final separator = tzMinTotal.isNegative ? '-' : '+';
    final tzHours = (tzMinTotal / 60).floor().abs().toString().padLeft(2, '0');
    final tzRemainMins = (tzMinTotal % 60).abs().toString().padLeft(2, '0');
    final date = now.toIso8601String().replaceAll(':', '_');
    final String stamper = '$date$separator${tzHours}_$tzRemainMins';
    print('Backup stamp will be: $stamper');
    final appInfo = await AppInfo.make();
    if (appInfo.sessions.isEmpty) {
      print('⚠️ No active sessions found.');
    } else {
      final encoded = json.encode(appInfo.sessions);
      final f = await File('${appInfo.appDocPath}/sessions_backup_$stamper')
          .create(exclusive: true);
      f.writeAsString(encoded);
      print('✔️ Sessions backed up ');
    }

    if (appInfo.accounts.isEmpty) {
      print('⚠️ No account data found.');
    } else {
      for (final a in appInfo.accounts) {
        await Directory('${appInfo.appDocPath}/$a')
            .rename('${appInfo.appDocPath}/${a}_backup_$stamper');
        print('✔️ $a backed up ');
      }
    }

    await appInfo.preferences.clear();
    print('✔️ All reset');
    exit(0);
  }
}
