import 'package:acter/features/activities/widgets/security_and_privacy_section/uncomfirmed_email_widget.dart';
import 'package:acter/features/backups/providers/backup_state_providers.dart';
import 'package:acter/features/backups/types.dart';
import 'package:acter/features/backups/widgets/backup_state_widget.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget? buildSecurityAndPrivacySectionWidget(
  BuildContext context,
  WidgetRef ref,
) {
  final List<Widget> securityWidgetList = [];

  final stateEnabled = ref.watch(backupStateProvider) == RecoveryState.enabled;
  if (!stateEnabled) {
    securityWidgetList.add(BackupStateWidget());
  }

  //Add Unconfirmed Emails Widget if there are unconfirmed emails
  final unconfirmedEmailWidget = buildUnconfirmedEmailWidget(context, ref);
  if (unconfirmedEmailWidget != null) {
    securityWidgetList.add(unconfirmedEmailWidget);
  }

  //FIXME: disabled until this flow actually works well
  //Add Sessions Widget
  // final sessions = buildSessionsWidget(context, ref);
  // if (sessions != null) securityWidgetList.add(sessions);

  //If there are no security widgets, return null
  if (securityWidgetList.isEmpty) return null;

  return Column(
    children: [
      SectionHeader(
        title: L10n.of(context).securityAndPrivacy,
        showSectionBg: false,
        isShowSeeAllButton: false,
      ),
      ...securityWidgetList,
    ],
  );
}
