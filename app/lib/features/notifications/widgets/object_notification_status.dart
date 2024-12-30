import 'package:acter/features/notifications/actions/subscribe_object_push.dart';
import 'package:acter/features/notifications/actions/unsubscribe_object_push.dart';
import 'package:acter/features/notifications/providers/object_notifications_settings_provider.dart';
import 'package:acter/features/notifications/types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ObjectNotificationStatus extends ConsumerWidget {
  final String objectId;
  final SubscriptionSubType? subType;
  const ObjectNotificationStatus({
    required this.objectId,
    this.subType,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watched = ref
        .watch(
          isPushNotificationSubscribedProvider(
            (objectId: objectId, subType: subType),
          ),
        )
        .valueOrNull;
    return switch (watched) {
      SubscriptionStatus.subscribed => IconButton(
          onPressed: () {
            unsubscribeObjectPush(
              ref: ref,
              lang: L10n.of(context),
              objectId: objectId,
              subType: subType,
            );
          },
          icon: Icon(
            PhosphorIconsFill.bellRinging,
          ),
        ),
      SubscriptionStatus.unsubscribed => IconButton(
          onPressed: () {
            subscribeObjectPush(
              ref: ref,
              lang: L10n.of(context),
              objectId: objectId,
              subType: subType,
            );
          },
          icon: Icon(
            PhosphorIconsFill.bellSlash,
          ),
        ),
      SubscriptionStatus.parentSubscribed => IconButton(
          onPressed: () {
            EasyLoading.showToast(L10n.of(context).subscribedToParent);
          },
          icon: Icon(
            PhosphorIconsThin.bell,
            color: Theme.of(context).disabledColor,
          ),
        ),
      _ => IconButton(
          onPressed: () {
            subscribeObjectPush(
              ref: ref,
              lang: L10n.of(context),
              objectId: objectId,
              subType: subType,
            );
          },
          icon: Icon(
            PhosphorIconsThin.bell,
          ),
        ),
    };
  }
}
