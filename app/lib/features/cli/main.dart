import 'package:acter/features/cli/commands/info.dart';
import 'package:args/command_runner.dart';

Future<void> cliMain(List<String> args) async {
  await CommandRunner(
    'acter',
    'community communication and casual organizing platform',
  )
    ..addCommand(InfoCommand())
    ..run(args);
}
