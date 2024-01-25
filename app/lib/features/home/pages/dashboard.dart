import 'dart:math';

import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/widgets/default_button.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/user_avatar.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/home/widgets/in_dashboard.dart';
import 'package:acter/features/home/widgets/my_events.dart';
import 'package:acter/features/home/widgets/my_spaces_section.dart';
import 'package:acter/features/home/widgets/my_tasks.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

class Dashboard extends ConsumerWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(alwaysClientProvider);
    final provider = ref.watch(featuresProvider);
    bool isActive(f) => provider.isActive(f);

    List<Widget> children = [];

    if (isActive(LabsFeature.tasks)) {
      children.add(const MyTasksSection(limit: 5));
    }

    if (isActive(LabsFeature.events)) {
      children.add(const MyEventsSection(limit: 5));
    }

    if (children.isEmpty) {
      children.add(const SliverToBoxAdapter(child: MySpacesSection()));
    } else {
      children.insert(0, const MySpacesSection(limit: 5));
      final widthCount = (MediaQuery.of(context).size.width ~/ 600).toInt();
      const int minCount = 2;
      // we have more than just the spaces screen, put them into a grid.
      children = [
        SliverToBoxAdapter(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.all(20),
              child: StaggeredGrid.count(
                crossAxisSpacing: 20,
                axisDirection: AxisDirection.down,
                crossAxisCount: max(min(widthCount, minCount), 1),
                children: children.toList(growable: false),
              ),
            ),
          ),
        ),
      ];
    }
    if (children.isEmpty) {
      return Center(
        heightFactor: 1.5,
        child: EmptyState(
          title: 'You are not a member of any space yet',
          subtitle:
              'Create or join space, to start organizing and collaborating!',
          image: 'assets/images/empty_home.svg',
          primaryButton: DefaultButton(
            onPressed: () => context.pushNamed(Routes.createSpace.name),
            title: 'Create New Space',
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.success,
              disabledBackgroundColor:
                  Theme.of(context).colorScheme.success.withOpacity(0.5),
            ),
          ),
          secondaryButton: DefaultButton(
            onPressed: () => context.pushNamed(Routes.joinSpace.name),
            title: 'Join Existing Space',
            isOutlined: true,
          ),
        ),
      );
    }

    return InDashboard(
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: primaryGradient),
          child: CustomScrollView(
            slivers: <Widget>[
              SliverAppBar(
                backgroundColor: Colors.transparent,
                actions: <Widget>[
                  IconButton(
                    icon: const Icon(Atlas.construction_tools_thin),
                    onPressed: () => context.pushNamed(Routes.settings.name),
                  ),
                  Visibility(
                    // FIXME: Only show mobile / when bottom bar shown...
                    visible: !client.isGuest(),
                    replacement: InkWell(
                      onTap: () => context.pushNamed(Routes.authLogin.name),
                      child: ActerAvatar(
                        mode: DisplayMode.DM,
                        avatarInfo: AvatarInfo(
                          uniqueId: UniqueKey().toString(),
                        ),
                      ),
                    ),
                    child: !isDesktop
                        ? Container(
                            key: Keys.avatar,
                            margin: const EdgeInsets.all(8),
                            child: InkWell(
                              onTap: () =>
                                  context.pushNamed(Routes.myProfile.name),
                              child: const UserAvatarWidget(size: 20),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
                title: isDesktop
                    ? const Text('My Dashboard')
                    : const Text('Overview'),
              ),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
