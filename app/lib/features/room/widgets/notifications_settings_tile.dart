import 'package:acter/common/providers/room_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';

String? notifToText(String curNotifStatus) {
  if (curNotifStatus == 'muted') {
    return 'Muted';
  } else if (curNotifStatus == 'mentions') {
    return 'Only on mentions and keywords';
  } else if (curNotifStatus == 'all') {
    return 'All Messages';
  } else {
    return null;
  }
}

class _NotificationSettingsTile extends ConsumerWidget {
  final String roomId;

  const _NotificationSettingsTile({
    required this.roomId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationStatus =
        ref.watch(roomNotificationStatusProvider(roomId));
    final defaultNotificationStatus =
        ref.watch(roomDefaultNotificationStatusProvider(roomId));
    final curNotifStatus = notificationStatus.valueOrNull;
    final tileTextTheme = Theme.of(context).textTheme.bodySmall;
    // ignore: always_declare_return_types
    return SettingsTile(
      title: Text(
        'Notifications',
        style: tileTextTheme,
      ),
      description: Text(
        notifToText(curNotifStatus ?? '') ??
            'Default (${notifToText(defaultNotificationStatus.valueOrNull ?? '') ?? 'undefined'})',
      ),
      leading: curNotifStatus == 'muted'
          ? const Icon(Atlas.bell_dash_bold, size: 18)
          : const Icon(Atlas.bell_thin, size: 18),
      trailing: PopupMenuButton<String>(
        initialValue: curNotifStatus,
        // Callback that sets the selected popup menu item.
        onSelected: (String newMode) async {
          debugPrint('new value: $newMode');
          final room = await ref.read(maybeRoomProvider(roomId).future);
          if (room == null) {
            EasyLoading.showError(
              'Room not found',
            );
            return;
          }
          EasyLoading.showProgress(0);
          // '' is a special case resetting to default.
          if (await room.setNotificationMode(
            newMode == '' ? null : newMode,
          )) {
            EasyLoading.showSuccess(
              'Notification status submitted',
            );
            await Future.delayed(const Duration(seconds: 1), () {
              // FIXME: we want to refresh the view but don't know
              //        when the event was confirmed form sync :(
              // let's hope that a second delay is reasonable enough
              ref.invalidate(maybeRoomProvider(roomId));
            });
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'all',
            child: ListTile(
              selected: curNotifStatus == 'all',
              title: const Text('All Messages'),
              trailing: curNotifStatus == 'all'
                  ? const Icon(Atlas.check_circle, size: 18)
                  : null,
            ),
          ),
          PopupMenuItem<String>(
            value: 'mentions',
            child: ListTile(
              selected: curNotifStatus == 'mentions',
              title: const Text('Mentions and Keywords only'),
              trailing: curNotifStatus == 'mentions'
                  ? const Icon(Atlas.check_circle, size: 18)
                  : null,
            ),
          ),
          PopupMenuItem<String>(
            value: 'muted',
            child: ListTile(
              selected: curNotifStatus == 'muted',
              title: const Text('Muted'),
              trailing: curNotifStatus == 'muted'
                  ? const Icon(Atlas.check_circle, size: 18)
                  : null,
            ),
          ),
          PopupMenuItem<String>(
            value: '',
            child: ListTile(
              selected: curNotifStatus == '',
              title: Text(
                'Default (${notifToText(defaultNotificationStatus.valueOrNull ?? '') ?? 'unedefined'})',
              ),
              trailing: curNotifStatus == ''
                  ? const Icon(Atlas.check_circle, size: 18)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationsSettingsTile extends AbstractSettingsTile {
  final String roomId;

  const NotificationsSettingsTile({
    required this.roomId,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _NotificationSettingsTile(roomId: roomId);
  }
}
