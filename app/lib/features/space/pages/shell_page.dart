import 'package:acter/common/dialogs/pop_up_dialog.dart';
import 'package:acter/common/models/profile_data.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
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
    final space = ref.watch(spaceProvider(widget.spaceIdOrAlias));
    return space.when(
      data: (space) {
        final profileData = ref.watch(spaceProfileDataProvider(space));
        return profileData.when(
          data: (profile) => Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: <Color>[
                      Theme.of(context).colorScheme.background,
                      Theme.of(context).colorScheme.neutral,
                    ],
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    _ShellToolbar(space, widget.spaceIdOrAlias),
                    _ShellHeader(widget.spaceIdOrAlias, profile),
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
          ),
          error: (error, stack) => Text('Loading failed: $error'),
          loading: () => const Text('Loading'),
        );
      },
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
    final membership = ref.watch(spaceMembershipProvider(spaceId)).valueOrNull;
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
            onTap: () => customMsgSnackbar(
              context,
              'Edit Space is not implemented yet',
            ),
            child: const Text('Settings'),
          ),
        );
      }

      if (membership.canString('CanInvite')) {
        submenu.add(
          PopupMenuItem(
            onTap: () => context.pushNamed(
              Routes.spaceInvite.name,
              pathParameters: {'spaceId': spaceId},
            ),
            child: const Text('Invite Users'),
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
            onTap: () => context.goNamed(Routes.dashboard.name),
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
    popUpDialog(
      context: context,
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
      btnText: 'No, Stay!',
      onPressedBtn: () => context.pop(),
      btn2Text: 'Yes, Leave!',
      onPressedBtn2: () async => {
        await space.leave(),
        // refresh spaces list
        ref.invalidate(spacesProvider),
        context.pop(),
        context.goNamed(Routes.dashboard.name),
      },
      btnColor: Colors.transparent,
      btn2Color: Theme.of(context).colorScheme.errorContainer,
      btnBorderColor: Theme.of(context).colorScheme.success,
    );
  }
}

class _ShellHeader extends ConsumerWidget {
  final String spaceId;
  final ProfileData spaceProfile;
  const _ShellHeader(this.spaceId, this.spaceProfile);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: <Widget>[
          SpaceParentBadge(
            spaceId: spaceId,
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
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  spaceProfile.displayName ?? spaceId,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Consumer(
                builder: (context, ref, child) {
                  final spaceMembers = ref.watch(
                    spaceMembersProvider(spaceId),
                  );
                  return spaceMembers.when(
                    data: (members) {
                      final membersCount = members.length;
                      if (membersCount > 5) {
                        // too many to display, means we limit to 5
                        members = members.sublist(0, 5);
                      }
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Wrap(
                          direction: Axis.horizontal,
                          spacing: -6,
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
                              )
                          ],
                        ),
                      );
                    },
                    error: (error, stack) =>
                        Text('Loading members failed: $error'),
                    loading: () => const CircularProgressIndicator(),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
