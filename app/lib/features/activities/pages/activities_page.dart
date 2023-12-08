import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/default_page_header.dart';
import 'package:acter/common/widgets/error_widget.dart';
import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/activities/providers/invitations_providers.dart';
import 'package:acter/features/activities/widgets/invitation_card.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    // ignore: unused_local_variable
    final allDone = ref.watch(hasActivitiesProvider) == HasActivities.none;
    final allSessions = ref.watch(unknownSessionsProvider);
    final invitations = ref.watch(invitationListProvider);
    final children = [];
    allSessions.when(
      data: (data) {
        final sessions = data.where((sess) => !sess.isVerified()).toList();
        if (sessions.length == 1) {
          children.add(
            SliverToBoxAdapter(
              child: SessionCard(
                key: oneUnverifiedSessionsCard,
                deviceRecord: sessions[0],
              ),
            ),
          );
        } else if (sessions.length > 1) {
          children.add(
            SliverToBoxAdapter(
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
            ),
          );
        }
      },
      error: (error, stack) {
        return const Text("Couldn't load unverified sessions");
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    if (invitations.isNotEmpty) {
      children.add(
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
      );
      children.add(
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
      );
    }
    if (children.isEmpty) {
      children.add(
        const SliverToBoxAdapter(
          child: Center(
            heightFactor: 1.5,
            child: ErrorWidgetTemplate(
              title: 'No Activity for you yet',
              subtitle:
                  'Notifies you about important things such as messages , invitations or requests.',
              image: 'assets/images/empty_activities.png',
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.neutral,
      body: CustomScrollView(
        slivers: <Widget>[
          PageHeaderWidget(
            title: 'Activities',
            sectionDecoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            expandedContent: size.width <= 600
                ? null
                : Text(
                    'All the important stuff requiring your attention can be found here',
                    softWrap: true,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
          ),
          ...children,
        ],
      ),
    );
  }
}
