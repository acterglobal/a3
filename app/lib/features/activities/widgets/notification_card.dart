import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/activities/util.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:go_router/go_router.dart';

class NotificationCard extends ConsumerWidget {
  final ffi.Notification notification;
  const NotificationCard({super.key, required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = !notification.read();
    final Widget? avatar;
    final Widget room;
    final roomId = notification.roomIdStr();
    final brief = extractBrief(notification);
    if (notification.hasRoom()) {
      if (notification.isActerSpace()) {
        final space = notification.space()!;
        avatar = Consumer(
          builder: (context, ref, child) {
            final spaceProfile = ref.watch(spaceProfileDataProvider(space));
            return InkWell(
              onTap: () => context.goNamed(
                Routes.space.name,
                pathParameters: {'spaceIdOrAlias': roomId},
              ),
              child: spaceProfile.when(
                data: (profile) => ActerAvatar(
                  mode: DisplayMode.Space,
                  displayName: profile.displayName,
                  uniqueId: roomId,
                  avatar: profile.getAvatarImage(),
                  size: 48,
                ),
                error: (err, stackTrace) {
                  debugPrint('Failed to load space due to $err');
                  return ActerAvatar(
                    mode: DisplayMode.Space,
                    displayName: roomId,
                    uniqueId: roomId,
                    size: 48,
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          },
        );
        room = Consumer(
          builder: (ctx, ref, child) {
            final spaceProfile = ref.watch(spaceProfileDataProvider(space));
            return spaceProfile.when(
              data: (value) => Text(value.displayName ?? roomId),
              error: (error, stackTrace) =>
                  Text('Failed to load space Text(roomId)due to $error'),
              loading: () => Text(roomId),
            );
          },
        );
      } else {
        final convo = notification.convo()!;
        avatar = Consumer(
          builder: (ctx, ref, child) {
            final profile = ref.watch(chatProfileDataProvider(convo));
            return InkWell(
              onTap: () => ctx.goNamed(
                Routes.chatroom.name,
                pathParameters: {'roomId': roomId},
                extra: convo,
              ),
              child: profile.when(
                data: (profile) => ActerAvatar(
                  mode: DisplayMode.GroupChat,
                  displayName: profile.displayName,
                  uniqueId: roomId,
                  avatar: profile.getAvatarImage(),
                  size: 48,
                ),
                error: (err, stackTrace) {
                  debugPrint('Failed to load room due to $err');
                  return ActerAvatar(
                    mode: DisplayMode.GroupChat,
                    displayName: roomId,
                    uniqueId: roomId,
                    size: 48,
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          },
        );
        room = Consumer(
          builder: (ctx, ref, child) {
            final profile = ref.watch(chatProfileDataProvider(convo));
            return profile.when(
              data: (value) => Text(value.displayName ?? roomId),
              error: (error, stackTrace) =>
                  Text('Failed to load room due to $error'),
              loading: () => Text(roomId),
            );
          },
        );
      }
    } else {
      avatar = null;
      room = Text(roomId);
    }
    return Card(
      elevation: unread ? 1 : 0,
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: SizedBox(height: 50, width: 50, child: avatar),
        onTap: () {
          switch (brief.route) {
            case Routes.chatroom:
              context.pushNamed(
                Routes.chatroom.name,
                pathParameters: {
                  'roomId': roomId
                }, // FIXME: fails at the moment
              );
              return;
            default:
            // nothing for now.
          }
        },
        title: Text(brief.title),
        subtitle: room,
      ),
    );
  }
}
