import 'package:acter/features/activities/widgets/security_and_privacy_section/uncomfirmed_email_widget.dart';
import 'package:acter/features/backups/widgets/backup_state_widget.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget? buildSecurityAndPrivacySectionWidget(
  BuildContext context,
  WidgetRef ref,
) {
  final List<Widget> securityWidgetList = [];

  //Add Backup State Widget if feature is enabled
  final isBackupFeatureEnabled =
      ref.watch(isActiveProvider(LabsFeature.encryptionBackup));
  if (isBackupFeatureEnabled) {
    securityWidgetList.add(BackupStateWidget(allowDisabling: true));
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
