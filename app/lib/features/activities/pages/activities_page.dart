import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/models/types.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/default_page_header.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/invitations/providers/invitations_providers.dart';
import 'package:acter/features/invitations/widgets/invitation_card.dart';
import 'package:acter/features/backups/widgets/backup_state_widget.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/invitations/widgets/has_invites_tile.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:acter/features/settings/providers/session_providers.dart';
import 'package:acter/features/settings/widgets/session_card.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ActivitiesPage extends ConsumerWidget {
  static const Key oneUnverifiedSessionsCard =
      Key('activities-one-unverified-session');
  static const Key unverifiedSessionsCard =
      Key('activities-unverified-sessions');
  static const Key unconfirmedEmails = Key('activities-has-unconfirmed-emails');

  const ActivitiesPage({super.key});

  Widget? renderSyncingState(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final syncState = ref.watch(syncStateProvider);
    final errorMsg = syncState.errorMsg;
    final retryDuration =
        syncState.countDown.map((countDown) => Duration(seconds: countDown));
    if (!ref.watch(hasFirstSyncedProvider)) {
      return SliverToBoxAdapter(
        child: Card(
          child: ListTile(
            leading: const Icon(Atlas.arrows_dots_rotate),
            title: Text(lang.renderSyncingTitle),
            subtitle: Text(lang.renderSyncingSubTitle),
          ),
        ),
      );
    } else if (errorMsg != null) {
      return SliverToBoxAdapter(
        child: Card(
          child: ListTile(
            leading: const Icon(Atlas.warning),
            title: Text(lang.errorSyncing(errorMsg)),
            subtitle: Text(
              retryDuration == null
                  ? lang.retrying
                  : lang.retryIn(
                      retryDuration.inMinutes
                          .remainder(60)
                          .toString()
                          .padLeft(2, '0'),
                      retryDuration.inSeconds
                          .remainder(60)
                          .toString()
                          .padLeft(2, '0'),
                    ),
            ),
          ),
        ),
      );
    }
    return null;
  }

  List<Widget>? renderInvitations(BuildContext context, WidgetRef ref) {
    final invitations = ref.watch(invitationListProvider);
    if (invitations.isEmpty) {
      return null;
    }
    if (invitations.length == 1) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            child: Text(
              L10n.of(context).invitations,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: InvitationCard(invitation: invitations.first),
        ),
      ];
    }
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 10,
            vertical: 5,
          ),
          child: Text(
            L10n.of(context).invitations,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: HasInvitesTile(count: invitations.length),
      ),
    ];
  }

  Widget? renderSessions(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final allSessions = ref.watch(unknownSessionsProvider);
    final err = allSessions.error;
    if (err != null) {
      return SliverToBoxAdapter(
        child: Text(lang.errorUnverifiedSessions(err.toString())),
      );
    }
    return allSessions.value.map((val) {
      final sessions = val.where((session) => !session.isVerified()).toList();
      if (sessions.isEmpty) {
        return null;
      } else if (sessions.length == 1) {
        return SliverToBoxAdapter(
          child: SessionCard(
            key: oneUnverifiedSessionsCard,
            deviceRecord: sessions[0],
          ),
        );
      } else {
        return SliverToBoxAdapter(
          child: Card(
            key: unverifiedSessionsCard,
            child: ListTile(
              leading: const Icon(Atlas.warning_bold),
              title: Text(
                lang.unverifiedSessionsTitle(sessions.length),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              trailing: OutlinedButton(
                onPressed: () {
                  context.pushNamed(Routes.settingSessions.name);
                },
                child: Text(lang.review),
              ),
            ),
          ),
        );
      }
    });
  }

  Widget? renderBackupSection(BuildContext context, WidgetRef ref) {
    return const SliverToBoxAdapter(child: BackupStateWidget());
  }

  Widget renderUnconfirmedEmailAddrs(BuildContext context) {
    final lang = L10n.of(context);
    return SliverToBoxAdapter(
      child: Card(
        key: unconfirmedEmails,
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 15),
        child: ListTile(
          onTap: () => context.goNamed(Routes.emailAddresses.name),
          leading: const Icon(Atlas.envelope_minus_thin),
          title: Text(lang.unconfirmedEmailsActivityTitle),
          subtitle: Text(lang.unconfirmedEmailsActivitySubtitle),
          trailing: const Icon(Icons.keyboard_arrow_right_outlined),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    // update the inner provider...
    // ignore: unused_local_variable
    final allDone = ref.watch(hasActivitiesProvider) == UrgencyBadge.none;
    final children = [];

    final syncStateWidget = renderSyncingState(context, ref);

    if (ref.watch(isActiveProvider(LabsFeature.encryptionBackup))) {
      final backups = renderBackupSection(context, ref);
      if (backups != null) {
        children.add(backups);
      }
    }
    final hasUnconfirmedEmails = ref.watch(hasUnconfirmedEmailAddresses);
    if (hasUnconfirmedEmails) {
      children.add(renderUnconfirmedEmailAddrs(context));
    }

    final sessions = renderSessions(context, ref);
    if (sessions != null) {
      children.add(sessions);
    }
    final invitations = renderInvitations(context, ref);
    if (invitations != null && invitations.isNotEmpty) {
      children.addAll(invitations);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          PageHeaderWidget(
            title: lang.activities,
            expandedContent: Text(
              lang.activitiesDescription,
              softWrap: true,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (syncStateWidget != null) syncStateWidget,
          if (children.isNotEmpty) ...children,
          if (children.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                heightFactor: 1.5,
                child: EmptyState(
                  title: lang.noActivityTitle,
                  subtitle: lang.noActivitySubtitle,
                  image: 'assets/images/empty_activity.svg',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
