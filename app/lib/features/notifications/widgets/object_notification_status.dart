import 'package:acter/features/notifications/actions/subscribe_object_push.dart';
import 'package:acter/features/notifications/actions/unsubscribe_object_push.dart';
import 'package:acter/features/notifications/providers/object_notifications_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ObjectNotificationStatus extends ConsumerWidget {
  final String objectId;
  // final String? subType;
  const ObjectNotificationStatus({
    required this.objectId,
    // this.subType,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watched = ref
        .watch(objectIsPushNotificationSubscribedProvider(objectId))
        .valueOrNull;
    final isSubscribed = watched == true;
    if (isSubscribed) {
      return IconButton(
        onPressed: () {
          unsubscribeObjectPush(ref: ref, objectId: objectId);
        },
        icon: Icon(PhosphorIconsThin.bell),
      );
    } else {
      return IconButton(
        onPressed: () {
          subscribeObjectPush(ref: ref, objectId: objectId);
        },
        icon: Icon(PhosphorIconsThin.bellSlash),
      );
    }
  }
}
