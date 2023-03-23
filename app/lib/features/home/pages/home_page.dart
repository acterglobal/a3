import 'dart:io';

import 'package:acter/common/dialogs/logout_confirmation.dart';
import 'package:acter/features/home/widgets/custom_selected_icon.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:date_format/date_format.dart';
import 'package:acter/features/chat/controllers/chat_list_controller.dart';
import 'package:acter/features/chat/controllers/chat_room_controller.dart';
import 'package:acter/features/chat/controllers/receipt_controller.dart';
import 'package:acter/features/home/controllers/home_controller.dart';
import 'package:acter/features/home/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shake/shake.dart';
import 'package:go_router/go_router.dart';

class SidebarNavigationItem extends NavigationRailDestination {
  final String initialLocation;

  const SidebarNavigationItem(
      {required this.initialLocation,
      required Widget icon,
      required Widget label})
      : super(icon: icon, label: label);
}

class BottombarNavigationItem extends BottomNavigationBarItem {
  final String initialLocation;

  const BottombarNavigationItem({
    required this.initialLocation,
    required Widget icon,
    String? label,
    Widget? activeIcon,
  }) : super(icon: icon, activeIcon: activeIcon, label: label);
}

class HomePage extends ConsumerStatefulWidget {
  final Widget child;
  const HomePage({super.key, required this.child});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  ScreenshotController screenshotController = ScreenshotController();
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();
  final desktopPlatforms = [
    TargetPlatform.linux,
    TargetPlatform.macOS,
    TargetPlatform.windows
  ];
  late bool bugReportVisible;
  late ShakeDetector detector;

  final sideBarNav = [];

  int get _selectedSidebarIndex =>
      _locationToSidebarIndex(GoRouter.of(context).location);

  int _locationToSidebarIndex(String location) {
    final index =
        sideBarNav.indexWhere((t) => location.startsWith(t.initialLocation));
    // if index not found (-1), return 0
    return index < 0 ? 0 : index;
  }

  // callback used to navigate to the desired tab
  void _onSidebarItemTapped(BuildContext context, int tabIndex) {
    if (tabIndex != _selectedSidebarIndex) {
      // go to the initial location of the selected tab (by index)
      context.go(sideBarNav[tabIndex].initialLocation);
    }
  }

  final bottomBarNav = [
    const BottombarNavigationItem(
      icon: Icon(Atlas.bullhorn_thin),
      activeIcon: CustomSelectedIcon(
        icon: Icon(Atlas.bullhorn_thin),
      ),
      label: 'Updates',
      initialLocation: '/updates',
    ),
    BottombarNavigationItem(
      icon: SvgPicture.asset(
        'assets/icon/acter.svg',
        height: 28,
        width: 28,
      ),
      activeIcon: CustomSelectedIcon(
        icon: SvgPicture.asset(
          'assets/icon/acter.svg',
          height: 28,
          width: 28,
        ),
      ),
      label: 'Overview',
      initialLocation: '/dashboard',
    ),
    const BottombarNavigationItem(
      icon: Icon(Atlas.chats_thin),
      activeIcon: CustomSelectedIcon(
        icon: Icon(Atlas.chats_thin),
      ),
      label: 'Chat',
      initialLocation: '/chat',
    )
  ];

  int get _selectedBottombarIndex =>
      _locationToBottombarIndex(GoRouter.of(context).location);

  int _locationToBottombarIndex(String location) {
    final index =
        bottomBarNav.indexWhere((t) => location.startsWith(t.initialLocation));
    // if index not found (-1), return 0
    return index < 0 ? 0 : index;
  }

  // callback used to navigate to the desired tab
  void _onBottombarItemTapped(BuildContext context, int tabIndex) {
    if (tabIndex != _selectedBottombarIndex) {
      // go to the initial location of the selected tab (by index)
      context.go(bottomBarNav[tabIndex].initialLocation);
    }
  }

  @override
  void initState() {
    super.initState();
    // shake is possible in only mobile
    if (Platform.isAndroid || Platform.isIOS) {
      bugReportVisible = false;
      detector = ShakeDetector.waitForStart(
        onPhoneShake: () {
          detector.stopListening();
          setState(() => bugReportVisible = true);
        },
      );
      detector.startListening();
    } else {
      bugReportVisible = true;
    }
  }

  @override
  void dispose() {
    Get.delete<ChatListController>();
    Get.delete<ChatRoomController>();
    Get.delete<ReceiptController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // get platform of context.
    final bool isDesktop =
        desktopPlatforms.contains(Theme.of(context).platform);
    final bool isGuest = ref.watch(homeStateProvider)!.isGuest();
    return ref.watch(homeStateProvider) != null
        ? Scaffold(
            body: Screenshot(
              controller: screenshotController,
              child: AdaptiveLayout(
                key: _key,
                bodyRatio: 0,
                primaryNavigation: isDesktop
                    ? SlotLayout(
                        config: <Breakpoint, SlotLayoutConfig?>{
                          // adapt layout according to platform.
                          Breakpoints.medium: SlotLayout.from(
                            key: const Key('primaryNavigation'),
                            builder: (BuildContext ctx) {
                              return AdaptiveScaffold.standardNavigationRail(
                                // Todo: Applied literal theme values here
                                // as NavigationRail is not considering
                                // NavigationRailTheme values from MaterialTheme.
                                // To be removed once issue is fixed in package.
                                labelType: NavigationRailLabelType.none,
                                backgroundColor: Theme.of(context)
                                    .navigationRailTheme
                                    .backgroundColor!,
                                selectedIconTheme: const IconThemeData(
                                  size: 18,
                                  color: Colors.white,
                                ),
                                unselectedIconTheme: const IconThemeData(
                                  size: 18,
                                  color: Colors.white,
                                ),
                                padding: const EdgeInsets.all(0),
                                leading: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    UserAvatarWidget(),
                                    Divider(
                                      height: 24,
                                      indent: 18,
                                      endIndent: 18,
                                    )
                                  ],
                                ),

                                selectedIndex: _selectedSidebarIndex,
                                onDestinationSelected: (index) =>
                                    _onSidebarItemTapped(context, index),
                                destinations: [
                                  SidebarNavigationItem(
                                    icon: SvgPicture.asset(
                                      'assets/icon/acter.svg',
                                      height: 24,
                                      width: 24,
                                    ),
                                    label: Text(
                                      'Overview',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                    initialLocation: '/dashboard',
                                  ),
                                  SidebarNavigationItem(
                                    icon: const Icon(Atlas.chats_thin),
                                    label: Text(
                                      'Chat',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                    initialLocation: '/chat',
                                  ),
                                ],
                                trailing: Expanded(
                                  child: Column(
                                    children: [
                                      const Divider(
                                        indent: 18,
                                        endIndent: 18,
                                      ),
                                      const Spacer(),
                                      Visibility(
                                        visible: !isGuest,
                                        child: InkWell(
                                          onTap: () =>
                                              confirmationDialog(context, ref),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 5,
                                            ),
                                            child: Column(
                                              children: [
                                                const Icon(
                                                  Atlas.exit_thin,
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    vertical: 5,
                                                  ),
                                                  child: Text(
                                                    'Log Out',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelSmall,
                                                    softWrap: false,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: GestureDetector(
                                          onTap: handleBugReport,
                                          child: Column(
                                            children: [
                                              const Icon(
                                                Icons.bug_report_rounded,
                                                color: Colors.white,
                                              ),
                                              Text(
                                                'Report',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall,
                                                softWrap: false,
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          Breakpoints.large: SlotLayout.from(
                            key: const Key('Large primaryNavigation'),
                            builder: (BuildContext ctx) {
                              return AdaptiveScaffold.standardNavigationRail(
                                // Todo: Applied literal theme values here
                                // as NavigationRail is not considering
                                // NavigationRailTheme values from MaterialTheme.
                                // To be removed once issue is fixed in package.
                                backgroundColor: Theme.of(context)
                                    .navigationRailTheme
                                    .backgroundColor!,
                                labelType: NavigationRailLabelType.all,
                                selectedLabelTextStyle:
                                    Theme.of(context).textTheme.labelSmall!,
                                selectedIconTheme: const IconThemeData(
                                  size: 18,
                                  color: Colors.white,
                                ),
                                unselectedIconTheme: const IconThemeData(
                                  size: 18,
                                  color: Colors.white,
                                ),
                                padding: const EdgeInsets.all(0),
                                leading: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      child: const UserAvatarWidget(),
                                    ),
                                    const Divider(
                                      indent: 18,
                                      endIndent: 18,
                                    )
                                  ],
                                ),
                                selectedIndex: _selectedSidebarIndex,
                                onDestinationSelected: (index) =>
                                    _onSidebarItemTapped(context, index),
                                destinations: [
                                  SidebarNavigationItem(
                                    icon: SvgPicture.asset(
                                      'assets/icon/acter.svg',
                                      height: 24,
                                      width: 24,
                                    ),
                                    label: Text(
                                      'Overview',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                      softWrap: false,
                                    ),
                                    initialLocation: '/dashboard',
                                  ),
                                  SidebarNavigationItem(
                                    icon: const Icon(Atlas.chats_thin),
                                    label: Text(
                                      'Chat',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall,
                                    ),
                                    initialLocation: '/chat',
                                  ),
                                ],
                                trailing: Expanded(
                                  child: Column(
                                    children: [
                                      const Divider(
                                        indent: 18,
                                        endIndent: 18,
                                      ),
                                      const Spacer(),
                                      Visibility(
                                        visible: !isGuest,
                                        child: InkWell(
                                          onTap: () =>
                                              confirmationDialog(context, ref),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 5,
                                            ),
                                            child: Column(
                                              children: [
                                                const Icon(
                                                  Atlas.exit_thin,
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    vertical: 5,
                                                  ),
                                                  child: Text(
                                                    'Log Out',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelSmall,
                                                    softWrap: false,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: GestureDetector(
                                          onTap: handleBugReport,
                                          child: Column(
                                            children: [
                                              const Icon(
                                                Icons.bug_report_rounded,
                                                color: Colors.white,
                                              ),
                                              Text(
                                                'Report',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall,
                                                softWrap: false,
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        },
                      )
                    : null,
                body: SlotLayout(
                  config: <Breakpoint, SlotLayoutConfig>{
                    Breakpoints.small: SlotLayout.from(
                      key: const Key('Body Small'),
                      builder: (BuildContext ctx) => widget.child,
                    ),
                    // show dashboard view on desktop only.
                    Breakpoints.mediumAndUp: isDesktop
                        ? SlotLayout.from(
                            key: const Key('Body Medium'),
                            builder: (BuildContext ctx) => Scaffold(
                              body: Center(
                                child: Text(
                                  'First Screen view to be implemented',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                            ),
                          )
                        : SlotLayout.from(
                            key: const Key('body-medium-mobile'),
                            builder: (BuildContext ctx) {
                              return widget.child;
                            },
                          ),
                  },
                ),
                // helper UI for body view but since its doesn't fit for mobile view,
                // hide it instead.
                secondaryBody: isDesktop
                    ? SlotLayout(
                        config: <Breakpoint, SlotLayoutConfig>{
                          Breakpoints.mediumAndUp: SlotLayout.from(
                            key: const Key('Body Medium'),
                            builder: (BuildContext ctx) {
                              return widget.child;
                            },
                          )
                        },
                      )
                    : null,
                bottomNavigation: isDesktop
                    ? SlotLayout(
                        config: <Breakpoint, SlotLayoutConfig>{
                          //In desktop, we have ability to adjust windows res,
                          // adjust to navbar as primary to smaller views.
                          Breakpoints.small: SlotLayout.from(
                            key: const Key('Bottom Navigation Small'),
                            inAnimation: AdaptiveScaffold.bottomToTop,
                            outAnimation: AdaptiveScaffold.topToBottom,
                            builder: (BuildContext ctx) => BottomNavigationBar(
                              currentIndex: _selectedBottombarIndex,
                              onTap: (index) =>
                                  _onBottombarItemTapped(context, index),
                              items: bottomBarNav,
                              type: BottomNavigationBarType.fixed,
                            ),
                          ),
                        },
                      )
                    : SlotLayout(
                        config: <Breakpoint, SlotLayoutConfig>{
                          // Navbar should be shown regardless of mobile screen sizes.
                          Breakpoints.smallAndUp: SlotLayout.from(
                            key: const Key('Bottom Navigation Small'),
                            inAnimation: AdaptiveScaffold.bottomToTop,
                            outAnimation: AdaptiveScaffold.topToBottom,
                            builder: (BuildContext ctx) => BottomNavigationBar(
                              currentIndex: _selectedBottombarIndex,
                              onTap: (index) =>
                                  _onBottombarItemTapped(context, index),
                              items: bottomBarNav,
                              type: BottomNavigationBarType.fixed,
                            ),
                          ),
                        },
                      ),
              ),
            ),
          )
        : const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
  }

  Future<void> handleBugReport() async {
    var appDocDir = await getApplicationDocumentsDirectory();
    // rage shake disallows dot in filename
    String timestamp = formatDate(
      DateTime.now(),
      [yyyy, '-', mm, '-', dd, '_', hh, '-', nn, '-', ss, '_', SSS],
    );
    var imagePath = await screenshotController.captureAndSave(
      appDocDir.path,
      fileName: 'screenshot_$timestamp.png',
    );
    if (imagePath != null) {
      Navigator.pushNamed(
        context,
        '/bug_report',
        arguments: {
          'screenshot': imagePath,
        },
      );
    } else {
      Navigator.pushNamed(context, '/bug_report');
    }
  }
}
