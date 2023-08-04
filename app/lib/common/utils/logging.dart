import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:logging/logging.dart';

Future<void> initLogging() async {
  if (isDevBuild) {
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
  } else {
    // FIXME: add code to support sending logs via rust API to file
  }
}
