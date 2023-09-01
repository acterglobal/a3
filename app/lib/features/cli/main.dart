import 'package:acter/features/cli/commands/backup-and-reset.dart';
import 'package:acter/features/cli/commands/info.dart';
import 'package:args/command_runner.dart';
import 'dart:io';

Future<void> cliMain(List<String> args) async {
  final builder = CommandRunner(
    'acter',
    'community communication and casual organizing platform',
  )
    ..addCommand(InfoCommand())
    ..addCommand(BackupAndResetCommand());
  await builder.run(args);
  exit(0);
}
