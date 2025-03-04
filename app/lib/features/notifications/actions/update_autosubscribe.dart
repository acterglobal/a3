import 'package:acter/features/settings/providers/app_settings_provider.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:acter/l10n/generated/l10n.dart';

final _log = Logger('a3::notifications::actions::update_auto_subscribe');

Future<bool> updateAutoSubscribe(
  WidgetRef ref,
  L10n lang,
  bool newValue,
) async {
  try {
    final appSettings = await ref.read(userAppSettingsProvider.future);
    final builder = appSettings.updateBuilder();
    builder.autoSubscribeOnActivity(newValue);
    return await builder.send();
  } catch (e, r) {
    _log.severe('updating auto subscribe failed', e, r);
    EasyLoading.showError(
      lang.settingsSubmittingFailed(e),
      duration: Duration(seconds: 3),
    );
    return false;
  }
}
