import 'dart:io';

import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

final backupFormatFinder = RegExp(r'_backup_[0-9-_T.+]+$');

class AppInfo {
  final String appDocPath;
  final SharedPreferences preferences;
  final List<String> sessions;
  final List<FileSystemEntity> logFiles;
  final List<String> accounts;

  const AppInfo(
    this.appDocPath,
    this.preferences,
    this.sessions,
    this.logFiles,
    this.accounts,
  );

  static Future<AppInfo> make() async {
    String appDocPath = await appDir();
    SharedPreferences pref = await sharedPrefs();
    List<String> sessions = (pref.getStringList(defaultSessionKey) ?? []);

    // directory
    final dir = Directory(appDocPath);
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
    return AppInfo(appDocPath, pref, sessions, logFiles, accounts);
  }
}
