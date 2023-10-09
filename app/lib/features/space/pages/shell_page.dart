import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/default_button.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter/common/widgets/spaces/space_info.dart';
import 'package:acter/common/widgets/spaces/space_parent_badge.dart';
import 'package:acter/features/space/widgets/top_nav.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/space/widgets/member_avatar.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Space;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SpaceShell extends ConsumerStatefulWidget {
  final String spaceIdOrAlias;
  final Widget child;

  const SpaceShell({
    super.key,
    required this.spaceIdOrAlias,
    required this.child,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SpaceShellState();
}

class _SpaceShellState extends ConsumerState<SpaceShell> {
  @override
  Widget build(BuildContext context) {
    // get platform of context.
    final profileData =
        ref.watch(spaceProfileDataForSpaceIdProvider(widget.spaceIdOrAlias));
    return profileData.when(
      data: (profile) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
          child: Column(
            children: <Widget>[
              _ShellToolbar(profile.space, widget.spaceIdOrAlias),
              _ShellHeader(widget.spaceIdOrAlias, profile.profile),
              TopNavBar(
                spaceId: widget.spaceIdOrAlias,
                key: Key('${widget.spaceIdOrAlias}::top-nav'),
              ),
              Expanded(
                child: widget.child,
              ),
            ],
          ),
        ),
      ),
      error: (error, stack) => Text('Loading failed: $error'),
      loading: () => const Text('Loading'),
    );
  }
}

class _ShellToolbar extends ConsumerWidget {
  final Space space;
  final String spaceId;
  const _ShellToolbar(this.space, this.spaceId);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(roomMembershipProvider(spaceId)).valueOrNull;
    final List<PopupMenuEntry> submenu = [];
    if (membership != null) {
      if (membership.canString('CanSetName')) {
        submenu.add(
          PopupMenuItem(
            onTap: () => context.pushNamed(
              Routes.editSpace.name,
              pathParameters: {'spaceId': spaceId},
              queryParameters: {'spaceId': spaceId},
            ),
            child: const Text('Edit Details'),
          ),
        );
        submenu.add(
          PopupMenuItem(
            onTap: () => context.pushNamed(
              Routes.spaceSettings.name,
              pathParameters: {'spaceId': spaceId},
            ),
            child: const Text('Settings'),
          ),
        );
      }
    }

    if (submenu.isNotEmpty) {
      // add divider
      submenu.add(const PopupMenuDivider());
    }
    submenu.add(
      PopupMenuItem(
        onTap: () => _handleLeaveSpace(context, space, ref),
        child: const Text('Leave Space'),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.canPop()
                ? context.pop()
                : context.goNamed(Routes.dashboard.name),
            child: Icon(
              Atlas.arrow_left,
              color: Theme.of(context).colorScheme.neutral5,
            ),
          ),
          const Spacer(),
          PopupMenuButton(
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).colorScheme.neutral5,
            ),
            iconSize: 28,
            color: Theme.of(context).colorScheme.surface,
            itemBuilder: (BuildContext context) => submenu,
          ),
        ],
      ),
    );
  }

  void _handleLeaveSpace(
    BuildContext context,
    Space space,
    WidgetRef ref,
  ) {
    showAdaptiveDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => DefaultDialog(
        title: Column(
          children: <Widget>[
            const Icon(Icons.person_remove_outlined),
            const SizedBox(height: 5),
            Text('Leave Space', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        subtitle: const Text(
          'Are you sure you want to leave this space?',
        ),
        actions: <Widget>[
          DefaultButton(
            onPressed: () => context.pop(),
            title: 'No Stay',
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Theme.of(context).colorScheme.success),
            ),
          ),
          DefaultButton(
            onPressed: () async {
              await space.leave();
              // refresh spaces list
              ref.invalidate(spacesProvider);
              if (!context.mounted) {
                return;
              }
              context.pop();
              context.pushNamed(Routes.dashboard.name);
            },
            title: 'Yes, Leave',
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShellHeader extends ConsumerWidget {
  final String spaceId;
  final ProfileData spaceProfile;
  const _ShellHeader(this.spaceId, this.spaceProfile);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Row(
        children: <Widget>[
          SpaceParentBadge(
            roomId: spaceId,
            badgeSize: 40,
            child: ActerAvatar(
              mode: DisplayMode.Space,
              displayName: spaceProfile.displayName,
              tooltip: TooltipStyle.None,
              uniqueId: spaceId,
              avatar: spaceProfile.getAvatarImage(),
              size: 80,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  spaceProfile.displayName ?? spaceId,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10, left: 10),
                child: SpaceInfo(spaceId: spaceId),
              ),
              Consumer(builder: spaceMembersBuilder),
            ],
          ),
        ],
      ),
    );
  }

  Widget spaceMembersBuilder(
    BuildContext context,
    WidgetRef ref,
    Widget? child,
  ) {
    final spaceMembers = ref.watch(spaceMembersProvider(spaceId));
    return spaceMembers.when(
      data: (members) {
        final membersCount = members.length;
        if (membersCount > 5) {
          // too many to display, means we limit to 5
          members = members.sublist(0, 5);
        }
        return Padding(
          padding: const EdgeInsets.only(left: 10),
          child: GestureDetector(
            onTap: () => context.goNamed(
              Routes.spaceMembers.name,
              pathParameters: {'spaceId': spaceId},
            ),
            child: Wrap(
              direction: Axis.horizontal,
              spacing: -12,
              children: [
                ...members.map(
                  (a) => MemberAvatar(member: a),
                ),
                if (membersCount > 5)
                  CircleAvatar(
                    child: Text(
                      '+${membersCount - 5}',
                      textAlign: TextAlign.center,
                      textScaleFactor: 0.8,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      error: (error, stack) => Text('Loading members failed: $error'),
      loading: () => const CircularProgressIndicator(),
    );
  }
}
