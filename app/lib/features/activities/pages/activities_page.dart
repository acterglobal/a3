import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/default_page_header.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/activities/providers/invitations_providers.dart';
import 'package:acter/features/activities/widgets/invitation_card.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/settings/providers/session_providers.dart';
import 'package:acter/features/settings/widgets/session_card.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      return const SliverToBoxAdapter(
        child: Card(
          child: ListTile(
            leading: Icon(Atlas.arrows_dots_rotate),
            title: Text('Syncing with your homeserver'),
            subtitle:
                Text('This might take a while if you have a large account'),
          ),
        ),
      );
    } else if (errorMsg != null) {
      return SliverToBoxAdapter(
        child: Card(
          child: ListTile(
            leading: const Icon(Atlas.warning),
            title: Text('Error syncing: $errorMsg'),
            subtitle: Text(
              retryDuration == null
                  ? 'retrying ...'
                  : 'Will retry in ${retryDuration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${retryDuration.inSeconds.remainder(60).toString().padLeft(2, '0')}',
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
            'Invitations',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext ctx, int index) {
            return InvitationCard(
              invitation: invitations[index],
              avatarColor: Colors.white,
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
        child: Text("Couldn't load unverified sessions: ${allSessions.error}"),
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
              'There are ${sessions.length} unverified sessions logged in',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            trailing: ElevatedButton(
              onPressed: () {
                context.pushNamed(Routes.settingSessions.name);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.neutral,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.success,
                ),
                foregroundColor: Theme.of(context).colorScheme.neutral6,
                textStyle: Theme.of(context).textTheme.bodySmall,
              ),
              child: const Text('Review'),
            ),
          ),
        ),
      );
    }
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
            title: 'Activities',
            sectionDecoration: const BoxDecoration(
              gradient: primaryGradient,
            ),
            expandedContent: Text(
              'All the important stuff requiring your attention can be found here',
              softWrap: true,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          ...children,
          if (renderEmptyState)
            const SliverToBoxAdapter(
              child: Center(
                heightFactor: 1.5,
                child: EmptyState(
                  title: 'No Activity for you yet',
                  subtitle:
                      'Notifies you about important things such as messages, invitations or requests.',
                  image: 'assets/images/empty_activity.svg',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
