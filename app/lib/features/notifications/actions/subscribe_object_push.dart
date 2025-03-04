import 'package:acter/features/notifications/providers/notification_settings_providers.dart';
import 'package:acter/features/notifications/providers/object_notifications_settings_provider.dart';
import 'package:acter/features/notifications/types.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/extensions/options.dart';
import 'package:logging/logging.dart';
import 'package:acter/l10n/generated/l10n.dart';

final _log = Logger('a3::notifications::actions::unsubscribe');

Future<bool> subscribeObjectPush({
  required WidgetRef ref,
  required String objectId,
  required L10n lang,
  SubscriptionSubType? subType,
}) async {
  try {
    final pushSettings = await ref.read(notificationSettingsProvider.future);
    final res = await pushSettings.subscribeObjectPush(
      objectId,
      subType.map((q) => q.asType()),
    );
    ref.invalidate(
      pushNotificationSubscribedStatusProvider((
        objectId: objectId,
        subType: subType,
      )),
    );
    return res;
  } catch (error, stack) {
    _log.severe(
      'subscribe Object Push for $objectId ($subType) failed',
      error,
      stack,
    );
    EasyLoading.showError(
      lang.settingsSubmittingFailed(error),
      duration: Duration(seconds: 3),
    );
    return false;
  }
}
