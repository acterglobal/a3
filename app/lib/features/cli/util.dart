import 'dart:io';

import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';

final backupFormatFinder = RegExp(r'_backup_[0-9-_T.+]+$');

class AppInfo {
  final String appDocPath;
  final List<String> sessions;
  final List<FileSystemEntity> logFiles;
  final List<String> accounts;

  const AppInfo(this.appDocPath, this.sessions, this.logFiles, this.accounts);

  static Future<AppInfo> make() async {
    String appDocPath = await appDir();
    List<String> sessions = await ActerSdk.sessionKeys() ?? [];

    // directory
    final dir = Directory(appDocPath);
    final dirEntries = await dir.list().toList();
    final logFiles =
        dirEntries
            .where(
              (x) =>
                  x.path.endsWith('.log') &&
                  FileSystemEntity.isFileSync(x.path),
            )
            .toList();
    final accounts =
        dirEntries
            .where((x) => FileSystemEntity.isDirectorySync(x.path))
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
                  !backupFormatFinder.hasMatch(
                    f,
                  ), // only show the ones indicating a username
            )
            .toList();
    logFiles.sort(
      // latest first
      (a, b) => FileStat.statSync(
        b.path,
      ).changed.compareTo(FileStat.statSync(a.path).changed),
    );
    return AppInfo(appDocPath, sessions, logFiles, accounts);
  }
}
