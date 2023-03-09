import 'dart:io';

import 'package:date_format/date_format.dart';
import 'package:effektio/common/themes/seperated_themes.dart';
import 'package:effektio/common/utils/constants.dart';
import 'package:effektio/features/chat/controllers/chat_list_controller.dart';
import 'package:effektio/features/chat/controllers/chat_room_controller.dart';
import 'package:effektio/features/chat/controllers/receipt_controller.dart';
import 'package:effektio/features/home/controllers/home_controller.dart';
import 'package:effektio/features/home/widgets/home_widget.dart';
import 'package:effektio/features/home/widgets/logout_button.dart';
import 'package:effektio/features/home/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shake/shake.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final PageController pageController;
  ScreenshotController screenshotController = ScreenshotController();
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();
  final desktopPlatforms = [
    TargetPlatform.linux,
    TargetPlatform.macOS,
    TargetPlatform.windows
  ];
  late bool bugReportVisible;
  late ShakeDetector detector;

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: _selectedIndex);
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
    final sdkState = ref.watch(homeStateProvider);
    return sdkState
        ? Scaffold(
            body: Screenshot(
              controller: screenshotController,
              child: AdaptiveLayout(
                key: _key,
                bodyRatio: 0.2,
                primaryNavigation: isDesktop
                    ? SlotLayout(
                        config: <Breakpoint, SlotLayoutConfig?>{
                          // adapt layout according to platform.
                          Breakpoints.medium: SlotLayout.from(
                            key: const Key('primaryNavigation'),
                            builder: (_) {
                              return AdaptiveScaffold.standardNavigationRail(
                                onDestinationSelected: (int index) {
                                  setState(() {
                                    _selectedIndex = index;
                                    pageController.jumpToPage(_selectedIndex);
                                  });
                                },
                                leading: const UserAvatarWidget(
                                    isExtendedRail: false),
                                trailing:
                                    const LogOutButton(isExtendedRail: false),
                                selectedIndex: _selectedIndex,
                                destinations: <NavigationRailDestination>[
                                  NavigationRailDestination(
                                    icon: newsFeedIcon(),
                                    label: const Text('Updates'),
                                  ),
                                  NavigationRailDestination(
                                    icon: pinsIcon(),
                                    label: const Text('Pins'),
                                  ),
                                  NavigationRailDestination(
                                    icon: tasksIcon(),
                                    label: const Text('Tasks'),
                                  ),
                                  NavigationRailDestination(
                                    icon: chatIcon(),
                                    label: const Text('Chat'),
                                  ),
                                ],
                              );
                            },
                          ),

                          Breakpoints.large: SlotLayout.from(
                            key: const Key('Large primaryNavigation'),
                            builder: (_) =>
                                AdaptiveScaffold.standardNavigationRail(
                              onDestinationSelected: (int index) {
                                setState(() {
                                  _selectedIndex = index;
                                  pageController.jumpToPage(_selectedIndex);
                                });
                              },
                              selectedIndex: _selectedIndex,
                              extended: true,
                              leading:
                                  const UserAvatarWidget(isExtendedRail: true),
                              trailing:
                                  const LogOutButton(isExtendedRail: true),
                              destinations: <NavigationRailDestination>[
                                NavigationRailDestination(
                                  icon: newsFeedIcon(),
                                  label: const Text('Updates'),
                                ),
                                NavigationRailDestination(
                                  icon: pinsIcon(),
                                  label: const Text('Pins'),
                                ),
                                NavigationRailDestination(
                                  icon: tasksIcon(),
                                  label: const Text('Tasks'),
                                ),
                                NavigationRailDestination(
                                  icon: chatIcon(),
                                  label: const Text('Chat'),
                                ),
                              ],
                            ),
                          )
                        },
                      )
                    : null,
                body: SlotLayout(
                  config: <Breakpoint, SlotLayoutConfig>{
                    Breakpoints.small: SlotLayout.from(
                      key: const Key('Body Small'),
                      builder: (_) => HomeWidget(pageController),
                    ),
                    // show dashboard view on desktop only.
                    Breakpoints.mediumAndUp: isDesktop
                        ? SlotLayout.from(
                            key: const Key('Body Medium'),
                            builder: (_) => const Scaffold(
                              body: Center(
                                child: Text(
                                  'Dashboard view to be implemented',
                                  style: AppCommonTheme.appBarTitleStyle,
                                ),
                              ),
                            ),
                          )
                        : SlotLayout.from(
                            key: const Key('body-meduim-mobile'),
                            builder: (_) => HomeWidget(pageController),
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
                            builder: (_) => HomeWidget(pageController),
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
                            builder: (_) =>
                                AdaptiveScaffold.standardBottomNavigationBar(
                              currentIndex: _selectedIndex,
                              onDestinationSelected: (index) {
                                setState(() {
                                  _selectedIndex = index;
                                  pageController.jumpToPage(_selectedIndex);
                                });
                              },
                              destinations: <NavigationDestination>[
                                NavigationDestination(
                                  icon: newsFeedIcon(),
                                  label: '',
                                ),
                                NavigationDestination(
                                  icon: pinsIcon(),
                                  label: '',
                                ),
                                NavigationDestination(
                                  icon: tasksIcon(),
                                  label: '',
                                ),
                                NavigationDestination(
                                  icon: chatIcon(),
                                  label: '',
                                ),
                              ],
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
                            builder: (_) =>
                                AdaptiveScaffold.standardBottomNavigationBar(
                              currentIndex: _selectedIndex,
                              onDestinationSelected: (index) {
                                setState(() {
                                  _selectedIndex = index;
                                  pageController.jumpToPage(_selectedIndex);
                                });
                              },
                              destinations: <NavigationDestination>[
                                NavigationDestination(
                                  icon: newsFeedIcon(),
                                  label: '',
                                ),
                                NavigationDestination(
                                  icon: pinsIcon(),
                                  label: '',
                                ),
                                NavigationDestination(
                                  icon: tasksIcon(),
                                  label: '',
                                ),
                                NavigationDestination(
                                  icon: chatIcon(),
                                  label: '',
                                ),
                              ],
                            ),
                          ),
                        },
                      ),
              ),
            ),
            floatingActionButton: Visibility(
              child: FloatingActionButton(
                onPressed: handleBugReport,
                backgroundColor: Colors.green,
                child: const Icon(Icons.bug_report_rounded),
              ),
              visible: bugReportVisible,
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
          )
        : const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: AppCommonTheme.primaryColor,
              ),
            ),
          );
  }

  Widget newsFeedIcon() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      key: Keys.newsSectionBtn,
      child: SvgPicture.asset('assets/images/newsfeed_linear.svg'),
    );
  }

  Widget pinsIcon() {
    return const Padding(
      padding: EdgeInsets.only(top: 10),
      child: Icon(FlutterIcons.pin_ent),
    );
  }

  Widget tasksIcon() {
    return const Padding(
      padding: EdgeInsets.only(top: 10),
      child: Icon(FlutterIcons.tasks_faw5s),
    );
  }

  Widget chatIcon() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SvgPicture.asset('assets/images/chat_linear.svg'),
    );
  }

  Widget notificationIcon() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SvgPicture.asset('assets/images/notification_linear.svg'),
    );
  }

  Future<void> handleBugReport() async {
    var appDocDir = await getApplicationDocumentsDirectory();
    // rageshake disallows dot in filename
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
