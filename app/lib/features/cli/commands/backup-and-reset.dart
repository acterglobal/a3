import 'dart:convert';
import 'dart:io';

import 'package:acter/config/env.g.dart';
import 'package:acter/features/cli/util.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

// ignore_for_file: avoid_print

class BackupAndResetCommand extends Command {
  @override
  final name = 'backup-and-reset';

  @override
  final description =
      'Backup accounts and sessions and reset the state to fresh and clean';

  BackupAndResetCommand() {
    argParser.addFlag('dry', help: 'dry run, do not actually write stuff');
  }

  @override
  Future<void> run() async {
    final isDry = argResults!.flag('dry');
    final now = DateTime.now();
    final tzMinTotal = now.timeZoneOffset.inMinutes;
    final separator = tzMinTotal.isNegative ? '-' : '+';
    final tzHours = (tzMinTotal / 60).floor().abs().toString().padLeft(2, '0');
    final tzRemainMins = (tzMinTotal % 60).abs().toString().padLeft(2, '0');
    final date = now.toIso8601String().replaceAll(':', '_');
    final String stamper = '$date$separator${tzHours}_$tzRemainMins';
    if (isDry) {
      print(' --- ⚠️ Running in Dry mode, not actually changing your data -- ');
    }
    // print('Backup stamp will be: $stamper');
    final appInfo = await AppInfo.make();
    if (appInfo.sessions.isEmpty) {
      print('⚠️ No active sessions found.');
    } else {
      final encoded = json.encode(appInfo.sessions);
      final filePath = p.join(appInfo.appDocPath, 'sessions_backup_$stamper');
      final f = await File(filePath).create(exclusive: true);
      if (!isDry) f.writeAsString(encoded);
      print('✔️ Sessions backed up to: $filePath');
    }

    if (appInfo.accounts.isEmpty) {
      print('⚠️ No account data found.');
    } else {
      for (final acc in appInfo.accounts) {
        final oldPath = p.join(appInfo.appDocPath, acc);
        final newPath = p.join(appInfo.appDocPath, '${acc}_backup_$stamper');
        if (!isDry) await Directory(oldPath).rename(newPath);
        print('✔️ $acc backed up: $newPath');
      }
    }

    if (!isDry) {
      await ActerSdk.storage.write(
        key: Env.defaultActerSession,
        value: json.encode([]),
      );
    }
    print('✔️ All reset');
    exit(0);
  }
}
