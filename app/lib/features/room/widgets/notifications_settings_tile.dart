import 'package:acter/common/providers/room_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:settings_ui/settings_ui.dart';

final _log = Logger('a3::room::notification_settings_tile');

String? notifToText(BuildContext context, String curNotifStatus) {
  if (curNotifStatus == 'muted') {
    return L10n.of(context).muted;
  } else if (curNotifStatus == 'mentions') {
    return L10n.of(context).mentionsAndKeywordsOnly;
  } else if (curNotifStatus == 'all') {
    return L10n.of(context).allMessages;
  } else {
    return null;
  }
}

class _NotificationSettingsTile extends ConsumerWidget {
  final String roomId;
  final String? title;
  final String? defaultTitle;
  final bool includeMentions;

  const _NotificationSettingsTile({
    required this.roomId,
    this.title,
    this.defaultTitle,
    this.includeMentions = true,
  });

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
        title ?? L10n.of(context).notifications,
        style: tileTextTheme,
      ),
      description: Text(
        notifToText(context, curNotifStatus ?? '') ??
            (defaultTitle ??
                L10n.of(context).defaultNotification(
                  '(${notifToText(context, defaultNotificationStatus.valueOrNull ?? '') ?? L10n.of(context).undefined})',
                )),
      ),
      leading: curNotifStatus == 'muted'
          ? const Icon(Atlas.bell_dash_bold, size: 18)
          : const Icon(Atlas.bell_thin, size: 18),
      trailing: PopupMenuButton<String>(
        initialValue: curNotifStatus,
        // Callback that sets the selected popup menu item.
        onSelected: (newMode) => onMenuSelected(context, ref, newMode),
        itemBuilder: (BuildContext context) => [
          PopupMenuItem<String>(
            value: 'all',
            child: notificationSettingItemUI(
              context,
              curNotifStatus == 'all',
              L10n.of(context).allMessages,
            ),
          ),
          if (includeMentions)
            PopupMenuItem<String>(
              value: 'mentions',
              child: notificationSettingItemUI(
                context,
                curNotifStatus == 'mentions',
                L10n.of(context).mentionsAndKeywordsOnly,
              ),
            ),
          PopupMenuItem<String>(
            value: 'muted',
            child: notificationSettingItemUI(
              context,
              curNotifStatus == 'muted',
              L10n.of(context).muted,
            ),
          ),
          PopupMenuItem<String>(
            value: '',
            child: notificationSettingItemUI(
              context,
              curNotifStatus == '',
              defaultTitle ??
                  L10n.of(context).defaultNotification(
                    '(${notifToText(context, defaultNotificationStatus.valueOrNull ?? '') ?? L10n.of(context).undefined})',
                  ),
            ),
          ),
        ],
      ),
    );
  }

  ListTile notificationSettingItemUI(
    BuildContext context,
    bool isSelected,
    String title,
  ) {
    return ListTile(
      selected: isSelected,
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: isSelected
          ? Icon(
              Atlas.check_circle,
              size: 18,
              color: Theme.of(context).colorScheme.onBackground,
            )
          : null,
    );
  }

  Future<void> onMenuSelected(
    BuildContext context,
    WidgetRef ref,
    String newMode,
  ) async {
    _log.info('new value: $newMode');
    EasyLoading.show(status: L10n.of(context).changingNotificationMode);
    try {
      final room = await ref.read(maybeRoomProvider(roomId).future);
      if (room == null) {
        if (!context.mounted) {
          EasyLoading.dismiss();
          return;
        }
        EasyLoading.showError(
          L10n.of(context).roomNotFound,
          duration: const Duration(seconds: 3),
        );
        return;
      }
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      // '' is a special case resetting to default.
      final res =
          await room.setNotificationMode(newMode == '' ? null : newMode);
      if (!res) {
        EasyLoading.dismiss();
        return;
      }
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(L10n.of(context).notificationStatusSubmitted);
      await Future.delayed(const Duration(seconds: 1), () {
        // FIXME: we want to refresh the view but don't know
        //        when the event was confirmed form sync :(
        // let's hope that a second delay is reasonable enough
        ref.invalidate(maybeRoomProvider(roomId));
      });
    } catch (e, st) {
      _log.severe('Failed to change notification mode', e, st);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).failedToChangeNotificationMode(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}

class NotificationsSettingsTile extends AbstractSettingsTile {
  final String roomId;
  final String? title;
  final String? defaultTitle;
  final bool? includeMentions;

  const NotificationsSettingsTile({
    required this.roomId,
    this.title,
    this.defaultTitle,
    this.includeMentions,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return _NotificationSettingsTile(
      roomId: roomId,
      title: title,
      defaultTitle: defaultTitle,
      includeMentions: includeMentions ?? true,
    );
  }
}
