import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/default_page_header.dart';
import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/activities/providers/invitations_providers.dart';
import 'package:acter/features/activities/providers/notifications_providers.dart';
import 'package:acter/features/activities/providers/session_providers.dart';
import 'package:acter/features/activities/providers/notifiers/notifications_list_notifier.dart';
import 'package:acter/features/activities/widgets/invitation_card.dart';
import 'package:acter/features/activities/widgets/notification_card.dart';
import 'package:acter/features/activities/widgets/session_card.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';

class ActivitiesPage extends ConsumerWidget {
  const ActivitiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = MediaQuery.of(context).size;
    // ignore: unused_local_variable
    final allDone = ref.watch(hasActivitiesProvider) == HasActivities.none;
    final allSessions = ref.watch(allSessionsProvider);
    final invitations = ref.watch(invitationListProvider);
    final children = [];
    allSessions.when(
      data: (data) {
        final sessions = data.where((sess) => !sess.isVerified()).toList();
        if (sessions.length == 1) {
          children.add(
            SliverToBoxAdapter(
              child: SessionCard(deviceRecord: sessions[0]),
            ),
          );
        } else if (sessions.length > 1) {
          children.add(
            SliverToBoxAdapter(
              child: Card(
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
    final weAreEmpty = children.isEmpty;

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
          RiverPagedBuilder<Next?, ffi.Notification>.autoDispose(
            firstPageKey: const Next(isStart: true),
            provider: notificationsListProvider,
            itemBuilder: (ctx, item, index) => NotificationCard(
              notification: item,
            ),
            noItemsFoundIndicatorBuilder: (ctx, controller) => weAreEmpty
                ? SizedBox(
                    // nothing found, even in the section before. Show nice fallback
                    height: 250,
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/images/undraw_project_completed_re_jr7u.svg',
                      ),
                    ),
                  )
                : const Text(''),
            pagedBuilder: (controller, builder) => PagedSliverList(
              pagingController: controller,
              builderDelegate: builder,
            ),
          ),
        ],
      ),
    );
  }
}
