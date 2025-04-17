import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/calendar_sync/calendar_sync.dart';
import 'package:acter/features/calendar_sync/calendar_sync_permission_page.dart'
    show CalendarSyncPermissionWidget;
import 'package:acter/features/calendar_sync/providers/calendar_sync_active_provider.dart';
import 'package:acter/features/device_permissions/calendar.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';

class CalendarSettingsPage extends ConsumerWidget {
  const CalendarSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return WithSidebar(
      sidebar: const SettingsPage(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(lang.calendar),
          automaticallyImplyLeading: !context.isLargeScreen,
        ),
        body: SettingsList(
          sections: [
            SettingsSection(
              tiles: [
                SettingsTile.switchTile(
                  enabled: isSupportedPlatform,
                  title: Text(lang.calendarSyncFeatureTitle),
                  description: Text(lang.calendarSyncFeatureDesc),
                  initialValue:
                      isSupportedPlatform &&
                      (ref.watch(isCalendarSyncActiveProvider).valueOrNull ??
                          true),
                  onToggle: (newVal) async {
                    if (newVal) {
                      final askPermission =  await shouldShowCalendarPermissionInfoPage();
                      if (askPermission) {
                        if (context.mounted) {
                          final granted = await showDialog<bool>(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return Dialog.fullscreen(
                                child: const CalendarSyncPermissionWidget(),
                              );
                            },
                          );

                          if (granted == true && context.mounted) {
                            await initCalendarSync(ignoreRejection: true);
                            EasyLoading.showToast('Acter Calendars synced');
                            ref.read(isCalendarSyncActiveProvider.notifier).set(true);
                          } else {
                            // If permission not granted, keep toggle off
                            ref.read(isCalendarSyncActiveProvider.notifier).set(false);
                          }
                        }
                      }else{
                         await initCalendarSync(ignoreRejection: true);
                         EasyLoading.showToast('Acter Calendars synced');
                         ref.read(isCalendarSyncActiveProvider.notifier).set(true);
                      }

                    }
                    else{
                      await clearActerCalendars();
                      EasyLoading.showToast('Acter Calendars removed');
                      ref.read(isCalendarSyncActiveProvider.notifier).set(false);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
