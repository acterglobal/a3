import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

final backupFormatFinder = RegExp(r'_backup_[0-9-_T.+]+$');

// ignore_for_file: avoid_print

class InfoCommand extends Command {
  @override
  final name = 'info';
  @override
  final description = 'Local info about your acter';

  InfoCommand();

  @override
  Future<void> run() async {
    print('Acter $versionName');
    print(' - Default Homeserver: $defaultServerName');
    print(' - Default Homeserver URL: $defaultServerUrl');

    String appDocPath = await appDir();
    SharedPreferences prefs = await sharedPrefs();
    List<String> sessions = (prefs.getStringList(defaultSessionKey) ?? []);
    print('Locally:');
    print(' - App Folder: $appDocPath');

    // directory
    final dir = new Directory(appDocPath);
    final dirEntries = await dir.list().toList();
    final logFiles = dirEntries
        .where(
          (x) => x.path.endsWith('.log') && FileSystemEntity.isFileSync(x.path),
        )
        .toList();
    final accounts = dirEntries
        .where(
          (x) => FileSystemEntity.isDirectorySync(x.path),
        )
        .map((a) {
          if (a.isAbsolute) {
            return a.path.substring(appDocPath.length + 1);
          } else {
            return a.path;
          }
        })
        .where(
          (f) =>
              f.startsWith('@') &&
              !backupFormatFinder
                  .hasMatch(f), // only show the ones indicating a username
        )
        .toList();
    logFiles.sort(
      // latest first
      (a, b) => FileStat.statSync(b.path)
          .changed
          .compareTo(FileStat.statSync(a.path).changed),
    );
    if (logFiles.isNotEmpty) {
      print(' - Latest log file: ${logFiles[0].path}');
    }

    print(' - Number of current sessions found: ${sessions.length}');
    if (accounts.isNotEmpty) {
      print(' - Data of sessions found: ${accounts.length}');
      for (final a in accounts) {
        print('    * $a');
      }
    }
    exit(0);
  }
}
