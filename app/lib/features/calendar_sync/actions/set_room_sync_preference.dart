import 'package:acter/features/room/providers/user_settings_provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::space::actions::activate');

Future<bool> setRoomSyncPreference(
  WidgetRef ref,
  L10n lang,
  String roomId,
  bool newValue,
) async {
  try {
    final settings = await ref.read(roomUserSettingsProvider(roomId).future);
    return await settings.setIncludeCalSync(newValue);
  } catch (e, s) {
    _log.severe('Setting room calendar settings failed', e, s);
    EasyLoading.showError(lang.error(e));
    return false;
  }
}
