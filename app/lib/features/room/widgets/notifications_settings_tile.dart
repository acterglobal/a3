import 'package:acter/common/providers/room_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:settings_ui/settings_ui.dart';

final _log = Logger('a3::room::notification_settings');

String? notifToText(BuildContext context, String curNotifStatus) {
  final lang = L10n.of(context);
  if (curNotifStatus == 'muted') {
    return lang.muted;
  } else if (curNotifStatus == 'mentions') {
    return lang.mentionsAndKeywordsOnly;
  } else if (curNotifStatus == 'all') {
    return lang.allMessages;
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
    final lang = L10n.of(context);
    final curNotifStatus =
        ref.watch(roomNotificationStatusProvider(roomId)).valueOrNull;
    final defNotifStatus =
        ref.watch(roomDefaultNotificationStatusProvider(roomId)).valueOrNull;
    final defStatusText = notifToText(context, defNotifStatus ?? '');
    final defNotifText =
        defaultTitle ??
        lang.defaultNotification('(${defStatusText ?? lang.undefined})');
    return SettingsTile(
      title: Text(
        title ?? lang.notifications,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      description: Text(
        notifToText(context, curNotifStatus ?? '') ?? defNotifText,
      ),
      leading: Icon(
        curNotifStatus == 'muted' ? Atlas.bell_dash_bold : Atlas.bell_thin,
        size: 18,
      ),
      trailing: PopupMenuButton<String>(
        initialValue: curNotifStatus,
        // Callback that sets the selected popup menu item.
        onSelected: (newMode) => onMenuSelected(context, ref, newMode),
        itemBuilder:
            (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'all',
                child: notificationSettingItemUI(
                  context,
                  curNotifStatus == 'all',
                  lang.allMessages,
                ),
              ),
              if (includeMentions)
                PopupMenuItem<String>(
                  value: 'mentions',
                  child: notificationSettingItemUI(
                    context,
                    curNotifStatus == 'mentions',
                    lang.mentionsAndKeywordsOnly,
                  ),
                ),
              PopupMenuItem<String>(
                value: 'muted',
                child: notificationSettingItemUI(
                  context,
                  curNotifStatus == 'muted',
                  lang.muted,
                ),
              ),
              PopupMenuItem<String>(
                value: '',
                child: notificationSettingItemUI(
                  context,
                  curNotifStatus == '',
                  defNotifText,
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
      title: Text(title, style: Theme.of(context).textTheme.bodyMedium),
      trailing:
          isSelected
              ? Icon(
                Atlas.check_circle,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface,
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
    final lang = L10n.of(context);
    EasyLoading.show(status: lang.changingNotificationMode);
    try {
      final room = await ref.read(maybeRoomProvider(roomId).future);
      if (room == null) {
        _log.severe('Room not found');
        if (!context.mounted) {
          EasyLoading.dismiss();
          return;
        }
        EasyLoading.showError(
          lang.roomNotFound,
          duration: const Duration(seconds: 3),
        );
        return;
      }
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      // '' is a special case resetting to default.
      final res = await room.setNotificationMode(
        newMode == '' ? null : newMode,
      );
      if (!res) {
        EasyLoading.dismiss();
        return;
      }
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(lang.notificationStatusSubmitted);
      await Future.delayed(const Duration(seconds: 1), () {
        // FIXME: we want to refresh the view but don’t know
        //        when the event was confirmed form sync :(
        // let’s hope that a second delay is reasonable enough
        ref.invalidate(maybeRoomProvider(roomId));
      });
    } catch (e, s) {
      _log.severe('Failed to change notification mode', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.failedToChangeNotificationMode(e),
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
