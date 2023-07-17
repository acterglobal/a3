import 'package:acter/common/dialogs/onboarding_dialog.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/widgets/user_avatar.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/home/widgets/my_spaces_section.dart';
import 'package:acter/features/home/widgets/my_events.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'dart:math';
import 'dart:async';

class Dashboard extends ConsumerStatefulWidget {
  const Dashboard({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DashboardState();
}

class _DashboardState extends ConsumerState<Dashboard> {
  @override
  void initState() {
    super.initState();
    _checkIfSpacesPresent();
  }

  void _checkIfSpacesPresent() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      final syncState = ref.watch(syncStateProvider);
      final hasFirstSynced = !syncState.syncing;
      if (!hasFirstSynced) {
        Future.delayed(
          const Duration(milliseconds: 250),
          () => _checkIfSpacesPresent(),
        );
        // we are still syncing, check again later
        return;
      }
      final spaces = await ref.watch(spacesProvider.future);
      if (spaces.isEmpty) {
        onBoardingDialog(
          context: context,
          btnText: 'Join Existing Space',
          btn2Text: 'Create New Space',
          onPressed1: () => context.pushNamed(Routes.joinSpace.name),
          onPressed2: () => context.pushNamed(Routes.createSpace.name),
          canDismissable: true,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = desktopPlatforms.contains(Theme.of(context).platform);
    final provider = ref.watch(featuresProvider);
    bool isActive(f) => provider.isActive(f);

    List<Widget> children = [];
    if (isActive(LabsFeature.events)) {
      children.add(const MyEventsSection());
    }

    if (children.isEmpty) {
      children.add(const SliverToBoxAdapter(child: MySpacesSection()));
    } else {
      children.add(const MySpacesSection(limit: 5));
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
    return Scaffold(
      body: Container(
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
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              backgroundColor: Colors.transparent,
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
                  ? const Text('My Dashboard')
                  : const Text('Overview'),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}
