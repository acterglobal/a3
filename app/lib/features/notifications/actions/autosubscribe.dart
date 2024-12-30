import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:acter/features/notifications/actions/subscribe_object_push.dart';
import 'package:acter/features/notifications/providers/notification_settings_providers.dart';
import 'package:acter/features/notifications/providers/object_notifications_settings_provider.dart';
import 'package:acter/features/notifications/types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

final _log = Logger('a3::notifications::actions::autosubscribe');

/// Automatically subscribe to the given objects for push notifications
///
/// Meant to be called upon interaction with an item. Will attempt to
/// add a push notifications rule to subscribe to this objects (or only its
/// subtype if given), unless the user actively unsubscribed to it.
Future<bool> autosubscribe({
  required WidgetRef ref,
  required String objectId,
  required L10n lang,
  SubscriptionSubType? subType,
}) async {
  if (!ref.read(isActiveProvider(LabsFeature.autoSubscribe))) {
    _log.info('AutoSubscribe Labs not activated');
    return false;
  }

  if (!await ref.read(autoSubscribeProvider.future)) {
    _log.info('AutoSubscribe deactivated');
    return false;
  }
  try {
    final currentStatus = await ref.read(
      pushNotificationSubscribedStatusProvider(
        (objectId: objectId, subType: subType),
      ).future,
    );
    return switch (currentStatus) {
      SubscriptionStatus.subscribed => true, // nothing to do,
      SubscriptionStatus.unsubscribed =>
        false, // user actively unsubscribed, ignore
      SubscriptionStatus.parentSubscribed =>
        true, // parent is already subscribed, nothing to do
      _ => await subscribeObjectPush(
          // none
          ref: ref,
          objectId: objectId,
          subType: subType,
          lang: lang,
        ),
    };
  } catch (error, stack) {
    Sentry.captureException(error, stackTrace: stack);
    _log.severe('autosubscribe to $objectId ($subType) failed', error, stack);
    return false;
  }
}
