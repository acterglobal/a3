import 'package:acter/common/extensions/options.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:args/command_runner.dart';

// ignore_for_file: avoid_print
const supportedKeys = {'http-proxy': proxyKey, 'rust-log': rustLogKey};

class ShowCommand extends Command {
  @override
  final name = 'show';
  @override
  final description = 'Show local setting';

  ShowCommand() {
    argParser.addOption(
      'key',
      allowed: supportedKeys.keys.toList(),
      help: 'key to show',
    );
    argParser.addFlag('all', abbr: 'a', help: 'show all keys');
  }

  @override
  Future<void> run() async {
    final results = argResults;
    if (results != null) {
      if (results['all']) {
        for (final title in supportedKeys.keys) {
          final key = supportedKeys[title].expect(
            'key of $title not available',
          );
          await printSetting(key, title);
        }
        return;
      }
      final title = results['key'];
      if (title != null) {
        final key = supportedKeys[title].expect('key of $title not available');
        return await printSetting(key, title);
      }
    }

    print('You must provide either a `key` or `--all` to show all');
  }

  Future<void> printSetting(String key, String title) async {
    final prefs = await sharedPrefs();
    final value = prefs.getString(key);
    if (value != null) {
      print('- $title ($key): $value');
    } else {
      print('- $title ($key) unset');
    }
  }
}

class SetCommand extends Command {
  @override
  final name = 'set';
  @override
  final description = 'Set local setting';

  SetCommand() {
    argParser.addOption(
      'key',
      allowed: supportedKeys.keys.toList(),
      help: 'key to set',
      mandatory: true,
    );
    argParser.addOption('value', help: 'value to set', mandatory: true);
  }

  @override
  Future<void> run() async {
    final results = argResults;
    if (results != null) {
      final title = results['key'];
      final value = results['value'];
      if (title != null && value != null) {
        final key = supportedKeys[title].expect('key of $title not available');
        return await setSetting(key, title, value);
      }
    }

    print('You must provide a `key` and `value` to set any parameter');
  }

  Future<void> setSetting(String key, String title, String value) async {
    final prefs = await sharedPrefs();
    await prefs.setString(key, value);
    print('$title ($key) set to $value');
  }
}

class ResetCommand extends Command {
  @override
  final name = 'reset';
  @override
  final description = 'Reset local setting';

  ResetCommand() {
    argParser.addOption(
      'key',
      allowed: supportedKeys.keys.toList(),
      help: 'key to reset',
    );
    argParser.addFlag('all', abbr: 'a', help: 'reset all keys');
  }

  @override
  Future<void> run() async {
    final results = argResults;
    if (results != null) {
      if (results['all']) {
        for (final title in supportedKeys.keys) {
          final key = supportedKeys[title].expect(
            'key of $title not available',
          );
          await resetSetting(key, title);
        }
        return;
      }
      final title = results['key'];
      if (title != null) {
        final key = supportedKeys[title].expect('key of $title not available');
        return await resetSetting(key, title);
      }
    }

    print('You must provide either a `key` or `--all` to reset the keys');
  }

  Future<void> resetSetting(String key, String title) async {
    final prefs = await sharedPrefs();
    await prefs.remove(key);
    print('$title ($key) reset');
  }
}

class SettingsCommand extends Command {
  @override
  final name = 'settings';
  @override
  final description = 'Local Settings of your acter instance';

  SettingsCommand() {
    addSubcommand(ResetCommand());
    addSubcommand(SetCommand());
    addSubcommand(ShowCommand());
  }
}
