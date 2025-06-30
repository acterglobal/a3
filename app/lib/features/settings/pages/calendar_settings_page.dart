import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/calendar_sync/calendar_sync.dart';
import 'package:acter/features/calendar_sync/providers/calendar_sync_active_provider.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:acter/features/calendar_sync/actions/calendar_sync_actions.dart';

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
                  // enabled: isSupportedPlatform,
                  title: Text(lang.calendarSyncFeatureTitle),
                  description: Text(lang.calendarSyncFeatureDesc),
                  initialValue:
                      isSupportedPlatform &&
                      (ref.watch(isCalendarSyncActiveProvider).valueOrNull ??
                          true),
                  onToggle: (newVal) async {
                    await handleCalendarSyncToggle(
                      context: context,
                      ref: ref,
                      newValue: newVal,
                    );
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
