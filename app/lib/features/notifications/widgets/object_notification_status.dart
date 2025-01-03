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
  final bool includeText;
  const ObjectNotificationStatus({
    required this.objectId,
    this.subType,
    this.includeText = false,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watched = ref
        .watch(
          pushNotificationSubscribedStatusProvider(
            (objectId: objectId, subType: subType),
          ),
        )
        .valueOrNull;
    final iconBtn = switch (watched) {
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
            EasyLoading.showToast(L10n.of(context).subscribedToParentMsg);
          },
          icon: Icon(
            PhosphorIconsFill.bellRinging,
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
    if (!includeText) {
      return iconBtn;
    }

    return TextButton.icon(
      icon: iconBtn.icon,
      onPressed: iconBtn.onPressed,
      label: Text(
        switch (watched) {
          SubscriptionStatus.subscribed => L10n.of(context).unsubscribeAction,
          SubscriptionStatus.parentSubscribed =>
            L10n.of(context).parentSubscribedAction,
          _ => L10n.of(context).subscribeAction,
        },
      ),
    );
  }
}
