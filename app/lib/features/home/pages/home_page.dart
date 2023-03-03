import 'package:date_format/date_format.dart';
import 'package:effektio/common/themes/seperated_themes.dart';
import 'package:effektio/common/utils/constants.dart';
import 'package:effektio/common/widgets/material_indicator.dart';
import 'package:effektio/features/chat/controllers/chat_list_controller.dart';
import 'package:effektio/features/chat/controllers/chat_room_controller.dart';
import 'package:effektio/features/chat/controllers/receipt_controller.dart';
import 'package:effektio/features/home/controllers/home_controller.dart';
import 'package:effektio/features/home/widgets/home_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  int tabIndex = 0;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 4, vsync: this);
    tabController.addListener(() {
      setState(() => tabIndex = tabController.index);
    });
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
    final client = ref.watch(clientProvider);
    return Screenshot(
      child: Scaffold(
        body: client.when(
          data: (data) => HomeWidget(tabController),
          error: (error, stackTrace) => const Center(
            child: Text("Couldn't fetch client"),
          ),
          loading: () => const Scaffold(
            body: Center(
              child: SizedBox(
                height: 50,
                width: 50,
                child: CircularProgressIndicator(
                  color: AppCommonTheme.primaryColor,
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: TabBar(
          labelColor: AppCommonTheme.primaryColor,
          unselectedLabelColor: AppCommonTheme.svgIconColor,
          controller: tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 12),
          indicator: const MaterialIndicator(
            height: 5,
            bottomLeftRadius: 8,
            bottomRightRadius: 8,
            topLeftRadius: 0,
            topRightRadius: 0,
            tabPosition: TabPosition.top,
            color: AppCommonTheme.primaryColor,
          ),
          tabs: [
            newsFeedTab(),
            pinsTab(),
            tasksTab(),
            chatTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            var appDocDir = await getApplicationDocumentsDirectory();
            // rageshake disallows dot in filename
            String timestamp = formatDate(
              DateTime.now(),
              [yyyy, '-', mm, '-', dd, '_', hh, '-', nn, '-', ss, '_', SSS],
            );
            var controller = Get.find<ScreenshotController>();
            var imagePath = await controller.captureAndSave(
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
          },
          backgroundColor: Colors.green,
          child: const Icon(Icons.bug_report_rounded),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      ),
      controller: Get.find<ScreenshotController>(),
    );
  }

  Widget newsFeedTab() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      key: Keys.newsSectionBtn,
      child: Tab(
        icon: tabIndex == 0
            ? SvgPicture.asset('assets/images/newsfeed_bold.svg')
            : SvgPicture.asset('assets/images/newsfeed_linear.svg'),
      ),
    );
  }

  Widget pinsTab() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: const Tab(icon: Icon(FlutterIcons.pin_ent)),
    );
  }

  Widget tasksTab() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: const Tab(
        icon: Icon(FlutterIcons.tasks_faw5s),
      ),
    );
  }

  Widget plusTab() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: Tab(
        icon: tabIndex == 2
            ? SvgPicture.asset(
                'assets/images/add.svg',
                color: AppCommonTheme.primaryColor,
              )
            : SvgPicture.asset('assets/images/add.svg'),
      ),
    );
  }

  Widget chatTab() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: Tab(
        icon: tabIndex == 3
            ? SvgPicture.asset('assets/images/chat_bold.svg')
            : SvgPicture.asset('assets/images/chat_linear.svg'),
      ),
    );
  }

  Widget notificationTab() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: Tab(
        icon: tabIndex == 4
            ? SvgPicture.asset('assets/images/notification_bold.svg')
            : SvgPicture.asset('assets/images/notification_linear.svg'),
      ),
    );
  }
}
