import 'dart:math';

import 'package:acter/common/dialogs/onboarding_dialog.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/widgets/user_avatar.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/home/widgets/my_spaces_section.dart';
import 'package:acter/features/home/widgets/my_events.dart';
import 'package:acter/features/home/widgets/my_tasks.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class Dashboard extends ConsumerWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final widthCount = (MediaQuery.of(context).size.width ~/ 300).toInt();
    final isDesktop = desktopPlatforms.contains(Theme.of(context).platform);
    const int minCount = 2;
    // get platform of context.
    return Scaffold(
      appBar: !isDesktop
          ? AppBar(
              actions: <Widget>[
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
                PopupMenuButton(
                  icon: Icon(
                    Atlas.plus_circle,
                    color: Theme.of(context).colorScheme.neutral5,
                  ),
                  iconSize: 28,
                  color: Theme.of(context).colorScheme.surface,
                  itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                    PopupMenuItem(
                      child: InkWell(
                        onTap: () => context.pushNamed(Routes.createSpace.name),
                        child: Row(
                          children: const <Widget>[
                            Text('Create Space'),
                            SizedBox(width: 10),
                            Icon(Atlas.connection),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      child: InkWell(
                        onTap: () => onBoardingDialog(
                          context: context,
                          btnText: 'Join Existing Space',
                          btn2Text: 'Create New Space',
                          onPressed1: () {},
                          onPressed2: () =>
                              context.goNamed(Routes.createSpace.name),
                          canDismissable: true,
                        ),
                        child: Row(
                          children: const <Widget>[
                            Text('Create Event'),
                            SizedBox(width: 10),
                            Icon(Atlas.calendar_dots),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      child: Row(
                        children: const <Widget>[
                          Text('Create ToDo'),
                          SizedBox(width: 10),
                          Icon(Atlas.check_folder)
                        ],
                      ),
                    ),
                  ],
                ),
                Visibility(
                  // FIXME: Only show mobile / when bottom bar shown...
                  visible: !ref.watch(clientProvider)!.isGuest(),
                  replacement: InkWell(
                    onTap: () => context.pushNamed(Routes.authLogin.name),
                    child: ActerAvatar(
                      uniqueId: UniqueKey().toString(),
                      mode: DisplayMode.User,
                    ),
                  ),
                  child: Container(
                    key: Keys.avatar,
                    margin: const EdgeInsets.all(8),
                    child: InkWell(
                      onTap: () => context.pushNamed(Routes.myProfile.name),
                      child: const UserAvatarWidget(),
                    ),
                  ),
                ),
              ],
              title: isDesktop
                  ? const Text('Acter Dashboard')
                  : const Text('Overview'),
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
