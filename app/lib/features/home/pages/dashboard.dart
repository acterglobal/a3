import 'package:acter/common/dialogs/onboarding_dialog.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/widgets/user_avatar.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/home/widgets/my_spaces_section.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/space/providers/space_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      final spaces = await ref.watch(spacesProvider.future);
      if (spaces.isEmpty) {
        onBoardingDialog(
          context: context,
          btnText: 'Join Existing Space',
          btn2Text: 'Create New Space',
          onPressed1: () {},
          onPressed2: () => context.goNamed(Routes.createSpace.name),
          canDismissable: true,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // final widthCount = (MediaQuery.of(context).size.width ~/ 300).toInt();
    final isDesktop = desktopPlatforms.contains(Theme.of(context).platform);
    // const int minCount = 2;
    // get platform of context.
    return Scaffold(
      // body: SingleChildScrollView(
      //   child: Container(
      //     margin: const EdgeInsets.all(20),
      //     child:  StaggeredGrid.count(
      //       crossAxisSpacing: 20,
      //       axisDirection: AxisDirection.down,
      //       crossAxisCount: min(widthCount, minCount),
      //       children: const [
      //         MyTasksSection(limit: 5),
      //         MySpacesSection(limit: 5),
      //         MyEventsSection(),
      //       ],
      //     ),
      //   ),
      // ),
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
                        onTap: () {
                          context.pop();
                          context.goNamed(Routes.createSpace.name);
                        },
                        child: Row(
                          children: const <Widget>[
                            Text('Create Space'),
                            Spacer(),
                            Icon(Atlas.connection),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      child: InkWell(
                        onTap: () => {},
                        child: Row(
                          children: const <Widget>[
                            Text('Join Space'),
                            Spacer(),
                            Icon(Atlas.calendar_dots),
                          ],
                        ),
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
            ),
            const SliverToBoxAdapter(
              child: MySpacesSection(),
            ),
          ],
        ),
      ),
    );
  }
}
