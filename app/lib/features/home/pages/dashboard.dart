import 'package:acter/common/snackbars/not_implemented.dart';
import 'package:acter/features/home/widgets/my_spaces_section.dart';
import 'package:acter/features/home/widgets/my_events.dart';
import 'package:acter/features/home/widgets/my_tasks.dart';
import 'package:acter/features/home/states/client_state.dart';
import 'package:acter/features/home/widgets/user_avatar.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/main/routing/routes.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'dart:math';

class Dashboard extends ConsumerWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final widthCount = (MediaQuery.of(context).size.width ~/ 300).toInt();

    const int minCount = 2;
    // get platform of context.
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Atlas.settings_monitor_thin),
            onPressed: () {
              showNotYetImplementedMsg(
                context,
                'Configuration Page for Dashboard not yet implemented',
              );
            },
          ),
          IconButton(
            icon: const Icon(Atlas.construction_tools_thin),
            onPressed: () {
              showNotYetImplementedMsg(
                context,
                'User Settings page not yet implemented',
              );
            },
          ),
          Visibility(
            // FIXME: Only show mobile / when bottom bar shown...
            visible: !ref.watch(clientProvider)!.isGuest(),
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
      ),
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