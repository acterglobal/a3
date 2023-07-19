import 'package:acter/common/notifications/notifications.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/default_page_header.dart';
import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/activities/providers/invitations_providers.dart';
import 'package:acter/features/activities/providers/notifications_providers.dart';
import 'package:acter/features/activities/providers/notifiers/notifications_list_notifier.dart';
import 'package:acter/features/activities/widgets/invitation_card.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:riverpod_infinite_scroll/riverpod_infinite_scroll.dart';

class NotificationCard extends ConsumerWidget {
  final ffi.Notification notification;
  const NotificationCard({super.key, required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = !notification.read();
    final Widget? avatar;
    final Widget title;
    final roomId = notification.roomIdStr();
    if (notification.hasRoom()) {
      if (notification.isActerSpace()) {
        final space = notification.space()!;
        avatar = Consumer(
          builder: (context, ref, child) {
            final spaceProfile = ref.watch(spaceProfileDataProvider(space));
            return spaceProfile.when(
              data: (profile) => InkWell(
                onTap: () => context.goNamed(
                  Routes.space.name,
                  pathParameters: {'spaceIdOrAlias': roomId},
                ),
                child: ActerAvatar(
                  mode: DisplayMode.Space,
                  displayName: profile.displayName,
                  uniqueId: roomId,
                  avatar: profile.getAvatarImage(),
                  size: 48,
                ),
              ),
              error: (error, stackTrace) => Text(
                  'Failed to load space due to $error'), // FIXME: fallback would be nice
              loading: () => const Center(child: CircularProgressIndicator()),
            );
          },
        );
        title = Consumer(
          builder: (context, ref, child) {
            final spaceProfile = ref.watch(spaceProfileDataProvider(space));
            return spaceProfile.when(
              data: (value) => Text(value.displayName ?? roomId),
              error: (error, stackTrace) =>
                  Text('Failed to load space Text(roomId)due to $error'),
              loading: () => Text(roomId),
            );
          },
        );
      } else {
        final convo = notification.convo()!;
        avatar = Consumer(
          builder: (context, ref, child) {
            final profile = ref.watch(chatProfileDataProvider(convo));
            return profile.when(
              data: (profile) => InkWell(
                onTap: () => context.goNamed(
                  Routes.chatroom.name,
                  pathParameters: {'roomId': roomId},
                  extra: convo,
                ),
                child: ActerAvatar(
                  mode: DisplayMode.GroupChat,
                  displayName: profile.displayName,
                  uniqueId: roomId,
                  avatar: profile.getAvatarImage(),
                  size: 48,
                ),
              ),
              error: (error, stackTrace) =>
                  Text('Failed to load room due to $error'),
              loading: () => const Center(child: CircularProgressIndicator()),
            );
          },
        );
        title = Consumer(
          builder: (context, ref, child) {
            final profile = ref.watch(chatProfileDataProvider(convo));
            return profile.when(
              data: (value) => Text(value.displayName ?? roomId),
              error: (error, stackTrace) =>
                  Text('Failed to load room due to $error'),
              loading: () => Text(roomId),
            );
          },
        );
      }
    } else {
      avatar = null;
      title = Text(roomId);
    }
    return Card(
      elevation: unread ? 1 : 0,
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: SizedBox(height: 50, width: 50, child: avatar),
        onTap: alert,
        title: title,
      ),
    );
  }

  void alert() {
    notify(null);
  }
}

class ActivitiesPage extends ConsumerWidget {
  const ActivitiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ignore: unused_local_variable
    final allDone = ref.watch(hasActivitiesProvider) == HasActivities.none;
    final invitations = ref.watch(invitationListProvider);
    final children = [];
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
            (BuildContext context, int index) {
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
      body: CustomScrollView(
        slivers: <Widget>[
          PageHeaderWidget(
            title: 'Activities',
            sectionColor: Colors.pink.shade600,
            actions: [
              IconButton(
                icon: const Icon(Atlas.funnel_sort_thin),
                onPressed: () {
                  customMsgSnackbar(
                    context,
                    'Activities filters not yet implemented',
                  );
                },
              ),
              IconButton(
                icon: const Icon(Atlas.gear_thin),
                onPressed: () {
                  customMsgSnackbar(
                    context,
                    'Notifications Settings page not yet implemented',
                  );
                },
              ),
            ],
            expandedContent: const Text(
              'All the important stuff requiring your attention can be found here',
            ),
          ),
          ...children,
          RiverPagedBuilder<Next?, ffi.Notification>.autoDispose(
            firstPageKey: const Next(isStart: true),
            provider: notificationsListProvider,
            itemBuilder: (context, item, index) =>
                NotificationCard(notification: item),
            noItemsFoundIndicatorBuilder: (context, controller) => weAreEmpty
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
