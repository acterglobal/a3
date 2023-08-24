import 'package:acter/features/cli/commands/backup-and-reset.dart';
import 'package:acter/features/cli/commands/info.dart';
import 'package:args/command_runner.dart';

Future<void> cliMain(List<String> args) async {
  CommandRunner(
    'acter',
    'community communication and casual organizing platform',
  )
    ..addCommand(InfoCommand())
    ..addCommand(BackupAndResetCommand())
    ..run(args);
}
