import 'dart:async';

import 'package:effektio/common/store/themes/AppTheme.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/chat_list_controller.dart';
import 'package:effektio/controllers/chat_room_controller.dart';
import 'package:effektio/controllers/receipt_controller.dart';
import 'package:effektio/l10n/l10n.dart';
import 'package:effektio/screens/HomeScreens/Notification.dart';
import 'package:effektio/screens/HomeScreens/faq/Overview.dart';
import 'package:effektio/screens/HomeScreens/chat/Overview.dart';
import 'package:effektio/screens/HomeScreens/news/News.dart';
import 'package:effektio/screens/OnboardingScreens/LogIn.dart';
import 'package:effektio/screens/OnboardingScreens/Signup.dart';
import 'package:effektio/screens/SideMenuScreens/AddToDo.dart';
import 'package:effektio/screens/SideMenuScreens/Gallery.dart';
import 'package:effektio/screens/SideMenuScreens/ToDo.dart';
import 'package:effektio/screens/UserScreens/SocialProfile.dart';
import 'package:effektio/widgets/AppCommon.dart';
import 'package:effektio/widgets/CrossSigning.dart';
import 'package:effektio/widgets/MaterialIndicator.dart';
import 'package:effektio/widgets/SideMenu.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart'
    show Client, EffektioSdk;
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show SyncState;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:themed/themed.dart';

void main() async {
  await startApp();
}

Future<void> startApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('google_fonts/LICENSE.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
  runApp(const Effektio());
}

class Effektio extends StatelessWidget {
  const Effektio({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Portal(
      child: Themed(
        child: GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          title: 'Effektio',
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: ApplicationLocalizations.supportedLocales,
          // MaterialApp contains our top-level Navigator
          initialRoute: '/',
          routes: <String, WidgetBuilder>{
            '/': (BuildContext context) => const EffektioHome(),
            '/login': (BuildContext context) => const LoginScreen(),
            '/profile': (BuildContext context) => const SocialProfileScreen(),
            '/signup': (BuildContext context) => const SignupScreen(),
            '/gallery': (BuildContext context) => const GalleryScreen(),
            '/todo': (BuildContext context) => const ToDoScreen(),
            '/addTodo': (BuildContext context) => const AddToDoScreen(),
          },
        ),
      ),
    );
  }
}

class EffektioHome extends StatefulWidget {
  const EffektioHome({Key? key}) : super(key: key);

  @override
  _EffektioHomeState createState() => _EffektioHomeState();
}

class _EffektioHomeState extends State<EffektioHome>
    with SingleTickerProviderStateMixin {
  late Future<Client> client;
  int tabIndex = 0;
  late TabController tabController;

  @override
  void initState() {
    super.initState();

    client = makeClient();
    tabController = TabController(length: 4, vsync: this);
    tabController.addListener(() {
      setState(() => tabIndex = tabController.index);
    });
  }

  @override
  void dispose() {
    if (Get.isRegistered<CrossSigning>()) {
      var crossSigning = Get.find<CrossSigning>();
      crossSigning.dispose();
      Get.delete<CrossSigning>();
    }
    Get.delete<ChatListController>();
    Get.delete<ChatRoomController>();
    Get.delete<ReceiptController>();

    super.dispose();
  }

  Future<Client> makeClient() async {
    final sdk = await EffektioSdk.instance;
    Client client = await sdk.currentClient;

    SyncState _ = client.startSync();
    //Start listening for cross signing events
    if (!client.isGuest()) {
      Get.put(CrossSigning(client: client));
      Get.put(ChatListController(client: client));
      Get.put(ChatRoomController(client: client));
      Get.put(ReceiptController(client: client));
    }
    return client;
  }

  PreferredSizeWidget? buildAppBar() {
    if (tabIndex <= 3) {
      return null;
    }
    List<String?> titles = <String?>[
      null,
      'Pins',
      'Tasks',
      'Chat',
    ];
    return AppBar(
      // title: navBarTitle(titles[tabIndex] ?? ''),
      centerTitle: true,
      primary: true,
      elevation: 1,
      leading: Builder(
        builder: (BuildContext context) {
          return IconButton(
            icon: Container(
              margin: const EdgeInsets.only(bottom: 10, left: 10),
              child: Image.asset('assets/images/hamburger.png'),
            ),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          );
        },
      ),
      actions: [
        IconButton(
          icon: Container(
            margin: const EdgeInsets.only(bottom: 10, right: 10),
            child: const Icon(Icons.search),
          ),
          onPressed: () {},
        )
      ],
    );
  }

  Widget buildNewsFeedTab() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: Tab(
        icon: tabIndex == 0
            ? SvgPicture.asset('assets/images/newsfeed_bold.svg')
            : SvgPicture.asset('assets/images/newsfeed_linear.svg'),
      ),
    );
  }

  Widget buildPinsTab() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: Tab(icon: Icon(FlutterIcons.pin_ent)),
    );
  }

  Widget buildTasksTab() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: Tab(
        icon: Icon(FlutterIcons.tasks_faw5s),
      ),
    );
  }

  Widget buildPlusTab() {
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

  Widget buildChatTab() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: Tab(
        icon: tabIndex == 3
            ? SvgPicture.asset('assets/images/chat_bold.svg')
            : SvgPicture.asset('assets/images/chat_linear.svg'),
      ),
    );
  }

  Widget buildNotificationTab() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: Tab(
        icon: tabIndex == 4
            ? SvgPicture.asset('assets/images/notification_bold.svg')
            : SvgPicture.asset('assets/images/notification_linear.svg'),
      ),
    );
  }

  Widget buildHomeScreen(BuildContext context, Client client) {
    return DefaultTabController(
      length: 4,
      key: const Key('bottom-bar'),
      child: SafeArea(
        child: Scaffold(
          appBar: buildAppBar(),
          body: TabBarView(
            controller: tabController,
            children: [
              NewsScreen(client: client),
              FaqOverviewScreen(client: client),
              const ToDoScreen(),
              ChatOverview(client: client),
            ],
          ),
          drawer: SideDrawer(client: client),
          bottomNavigationBar: TabBar(
            labelColor: AppCommonTheme.primaryColor,
            unselectedLabelColor: AppCommonTheme.svgIconColor,
            controller: tabController,
            indicator: const MaterialIndicator(
              height: 5,
              bottomLeftRadius: 8,
              bottomRightRadius: 8,
              topLeftRadius: 0,
              topRightRadius: 0,
              horizontalPadding: 12,
              tabPosition: TabPosition.top,
              color: AppCommonTheme.primaryColor,
            ),
            tabs: [
              buildNewsFeedTab(),
              buildPinsTab(),
              buildTasksTab(),
              buildChatTab(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Client>(
      future: client, // a previously-obtained Future<String> or null
      builder: (BuildContext context, AsyncSnapshot<Client> snapshot) {
        if (snapshot.hasData) {
          return buildHomeScreen(context, snapshot.requireData);
        } else if (snapshot.hasError) {
          return SizedBox(
            height: 40,
            width: 40,
            child: Text('${snapshot.error}'),
          );
        } else {
          return const Scaffold(
            body: Center(
              child: SizedBox(
                height: 50,
                width: 50,
                child: CircularProgressIndicator(
                  color: AppCommonTheme.primaryColor,
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
