import 'dart:math';

import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/user_avatar.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/home/widgets/my_events.dart';
import 'package:acter/features/home/widgets/my_spaces_section.dart';
import 'package:acter/features/home/widgets/my_tasks.dart';
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
    final client = ref.watch(clientProvider)!;
    final widthCount = (MediaQuery.of(context).size.width ~/ 300).toInt();
    final isDesktop = desktopPlatforms.contains(Theme.of(context).platform);
    const int minCount = 2;
    // get platform of context.
    return Scaffold(
      appBar: !isDesktop
          ? AppBar(
              actions: [
                IconButton(
                  icon: const Icon(Atlas.settings_monitor_thin),
                  onPressed: () {
                    customMsgSnackbar(
                      context,
                      'Configuration Page for Dashboard not yet implemented',
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Atlas.construction_tools_thin),
                  onPressed: () {
                    context.go('/settings');
                  },
                ),
                Visibility(
                  // FIXME: Only show mobile / when bottom bar shown...
                  visible: !client.isGuest(),
                  replacement: InkWell(
                    onTap: () => context.pushNamed(Routes.authLogin.name),
                    child: ActerAvatar(
                      uniqueId: UniqueKey().toString(),
                      mode: DisplayMode.User,
                    ),
                  ),
                  child: Container(
                    key: Keys.avatar,
                    margin: const EdgeInsets.only(top: 8),
                    child: InkWell(
                      onTap: () => context.pushNamed(Routes.myProfile.name),
                      child: const UserAvatarWidget(),
                    ),
                  ),
                ),
              ],
              title: const Text('Acter Dashboard'),
            )
          : null,
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(20),
          child: StaggeredGrid.count(
            crossAxisSpacing: 20,
            axisDirection: AxisDirection.down,
            crossAxisCount: min(widthCount, minCount),
            children: const [
              MyTasksSection(limit: 5),
              MySpacesSection(limit: 5),
              MyEventsSection(),
            ],
          ),
        ),
      ),
    );
  }
}
