import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/activities/widgets/security_and_privacy_section/sessions_widget.dart';
import 'package:acter/features/activities/widgets/security_privacy_widget.dart';
import 'package:acter/features/backups/widgets/backup_state_widget.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

Widget? buildSecurityAndPrivacySectionWidget(
    BuildContext context, WidgetRef ref) {
  final lang = L10n.of(context);

  final List<Widget> security = [];

  //Add Backup State Widget if feature is enabled
  final isBackupFeatureEnabled =
      ref.watch(isActiveProvider(LabsFeature.encryptionBackup));
  if (isBackupFeatureEnabled) security.add(BackupStateWidget());

  //Add Unconfirmed Emails Widget if there are unconfirmed emails
  final hasUnconfirmedEmails = ref.watch(hasUnconfirmedEmailAddresses);
  if (hasUnconfirmedEmails) {
    security.add(
      SecurityPrivacyWidget(
        icon: Atlas.envelope_minus_thin,
        iconColor: warningColor,
        title: lang.unconfirmedEmailsActivityTitle,
        subtitle: lang.unconfirmedEmailsActivitySubtitle,
        actions: [
          OutlinedButton(
            onPressed: () => context.goNamed(Routes.emailAddresses.name),
            child: Text(lang.confirmedEmailAddresses),
          ),
        ],
      ),
    );
  }

  final sessions = buildSessionsWidget(context, ref);
  if (sessions != null) security.add(sessions);

  //If there are no security widgets, return null
  if (security.isEmpty) return null;

  return Column(
    children: [
      SectionHeader(
        title: L10n.of(context).securityAndPrivacy,
        showSectionBg: false,
        isShowSeeAllButton: false,
      ),
      ...security,
    ],
  );
}
