+++
title = "Logging"

weight = 10
template = "docs/page.html"

[extra]
toc = true
top = false
+++

## Logging in Flutter

We use the `logging` package to log in flutter, which we then pass over to the Rust side to write both flutter and rust logs into a singular log file. Thus

## Enable / enhance logging

The log settings are configured via the `Settings -> Info -> Log Settings`. Click the entry to change the value. You can reset it by clicking `reset`. It requires a restart of the App to take effect.

### Conventions

To add logging to your module, you can use the following example code:

```dart

import 'package:logging/logging.dart';

final _log = Logger('a3::common::chat');

_log.info("some string");

try {
    // ,,
} catch (e, s) {
    _log.severe('reporting an error', e, s);
}
```

#### Naming modules

The convention is to name the loggers in snake_case with `::`-separators (as needed for rust convention). All Flutter app logs start with `a3::` followed by the `common`, `router` or the specific feature and followed by the lower section, any other separators may follow to your liking. e.g. `a3::common::chat` for the chat module in `common`.

Through this you can easily get the logs for an entire feature/section by settings it to `a3::router=trace` and become more granular while you debug.

#### Log Levels

Logging knows a few other log levels than we have in Rust side. They are mapped as follows:

```dart
    String level = 'trace';
    if (record.level == Level.WARNING) {
      level = 'warn';
    } else if (record.level == Level.SEVERE || record.level == Level.SHOUT) {
      level = 'error';
    } else if (record.level == Level.INFO) {
      level = 'info';
    } else if (record.level == Level.CONFIG) {
      level = 'debug';
    }
```
