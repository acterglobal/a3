import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';

import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/default_page_header.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/activities/providers/invitations_providers.dart';
import 'package:acter/features/activities/widgets/invitation_card.dart';
import 'package:acter/features/backups/widgets/backup_state_widget.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/settings/providers/session_providers.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter/features/settings/widgets/session_card.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ActivitiesPage extends ConsumerWidget {
  static const Key oneUnverifiedSessionsCard =
      Key('activities-one-unverified-session');
  static const Key unverifiedSessionsCard =
      Key('activities-unverified-sessions');
  const ActivitiesPage({super.key});

  Widget? renderSyncingState(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);
    final hasFirstSynced = !syncState.initialSync;
    final errorMsg = syncState.errorMsg;
    final retryDuration = syncState.countDown != null
        ? Duration(seconds: syncState.countDown!)
        : null;
    if (!hasFirstSynced) {
      return SliverToBoxAdapter(
        child: Card(
          child: ListTile(
            leading: const Icon(Atlas.arrows_dots_rotate),
            title: Text(L10n.of(context).renderSyncingTitle),
            subtitle: Text(L10n.of(context).renderSyncingSubTitle),
          ),
        ),
      );
    } else if (errorMsg != null) {
      return SliverToBoxAdapter(
        child: Card(
          child: ListTile(
            leading: const Icon(Atlas.warning),
            title: Text(L10n.of(context).errorSyncing(errorMsg)),
            subtitle: Text(
              retryDuration == null
                  ? L10n.of(context).retrying
                  : L10n.of(context).retryIn(
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
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext ctx, int index) {
            return InvitationCard(
              invitation: invitations[index],
            );
          },
          childCount: invitations.length,
        ),
      ),
    ];
  }

  Widget? renderSessions(BuildContext context, WidgetRef ref) {
    final allSessions = ref.watch(unknownSessionsProvider);
    if (allSessions.error != null) {
      return SliverToBoxAdapter(
        child: Text(
          L10n.of(context)
              .errorUnverifiedSessions(allSessions.error.toString()),
        ),
      );
    } else if (!allSessions.hasValue) {
      // we can ignore
      return null;
    }

    final sessions =
        allSessions.value!.where((session) => !session.isVerified()).toList();
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
              L10n.of(context).unverifiedSessionsTitle(sessions.length),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            trailing: OutlinedButton(
              onPressed: () {
                context.pushNamed(Routes.settingSessions.name);
              },
              child: Text(L10n.of(context).review),
            ),
          ),
        ),
      );
    }
  }

  Widget? renderBackupSection(BuildContext context, WidgetRef ref) {
    return const SliverToBoxAdapter(child: BackupStateWidget());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // update the inner provider...
    // ignore: unused_local_variable
    final allDone = ref.watch(hasActivitiesProvider) == HasActivities.none;
    final children = [];
    bool renderEmptyState = true;

    final syncState = renderSyncingState(context, ref);
    if (syncState != null) {
      // if all we have is this item, we still want to render the empty State...
      children.add(syncState);
    }

    if (ref.watch(featuresProvider).isActive(LabsFeature.encryptionBackup)) {
      final backups = renderBackupSection(context, ref);
      if (backups != null) {
        renderEmptyState = false;
        children.add(backups);
      }
    }
    final sessions = renderSessions(context, ref);
    if (sessions != null) {
      renderEmptyState = false;
      children.add(sessions);
    }
    final invitations = renderInvitations(context, ref);
    if (invitations != null && invitations.isNotEmpty) {
      renderEmptyState = false;
      children.addAll(invitations);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.neutral,
      body: CustomScrollView(
        slivers: <Widget>[
          PageHeaderWidget(
            title: L10n.of(context).activities,
            sectionDecoration: const BoxDecoration(
              gradient: primaryGradient,
            ),
            expandedContent: Text(
              L10n.of(context).activitiesDescription,
              softWrap: true,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          ...children,
          if (renderEmptyState)
            SliverToBoxAdapter(
              child: Center(
                heightFactor: 1.5,
                child: EmptyState(
                  title: L10n.of(context).noActivityTitle,
                  subtitle: L10n.of(context).noActivitySubtitle,
                  image: 'assets/images/empty_activity.svg',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
