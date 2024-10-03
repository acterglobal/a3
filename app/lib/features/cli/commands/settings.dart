import 'package:args/command_runner.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';

// ignore_for_file: avoid_print
const supportedKeys = {
  'http-proxy': proxyKey,
  'rust-log': rustLogKey,
};

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
        for (final entry in supportedKeys.entries) {
          await printSetting(entry.value, entry.key);
        }
        return;
      }
      String? key = results['key'];
      if (key != null) {
        final sk = supportedKeys[key];
        if (sk == null) throw '$key not supported';
        return await printSetting(sk, key);
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
    argParser.addOption(
      'value',
      help: 'value to set',
      mandatory: true,
    );
  }

  @override
  Future<void> run() async {
    final results = argResults;
    if (results != null) {
      String? key = results['key'];
      String? value = results['value'];
      if (key != null && value != null) {
        final sk = supportedKeys[key];
        if (sk == null) throw '$key not supported';
        await setSetting(sk, key, value);
        return;
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
        for (final entry in supportedKeys.entries) {
          await resetSetting(entry.value, entry.key);
        }
        return;
      }
      String? key = results['key'];
      if (key != null) {
        final sk = supportedKeys[key];
        if (sk == null) throw '$key not supported';
        await resetSetting(sk, key);
        return;
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
