import 'dart:async';
import 'dart:io';

import 'package:date_format/date_format.dart';
import 'package:effektio/common/snackbars/not_implemented.dart';
import 'package:effektio/common/themes/app_theme.dart';
import 'package:effektio/common/themes/seperated_themes.dart';
import 'package:effektio/common/utils/utils.dart';
import 'package:effektio/features/bug_report/pages/bug_report_page.dart';
import 'package:effektio/features/chat/controllers/chat_list_controller.dart';
import 'package:effektio/features/chat/controllers/chat_room_controller.dart';
import 'package:effektio/features/chat/controllers/receipt_controller.dart';
import 'package:effektio/features/chat/pages/chat_page.dart';
import 'package:effektio/l10n/l10n.dart';
import 'package:effektio/features/faq/pages/faq_page.dart';
import 'package:effektio/features/news/pages/news_page.dart';
import 'package:effektio/features/todo/pages/todo_page.dart';
import 'package:effektio/features/onboarding/pages/login_page.dart';
import 'package:effektio/features/onboarding/pages/sign_up_page.dart';
import 'package:effektio/features/gallery/pages/gallery_page.dart';
import 'package:effektio/features/profile/pages/social_profile_page.dart';
import 'package:effektio/features/cross_signing/cross_signing.dart';
import 'package:effektio/common/widgets/material_indicator.dart';
import 'package:effektio/common/widgets/side_menu.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart'
    show Client, EffektioSdk;
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show CreateGroupSettings, FfiBufferUint8, SyncState;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:themed/themed.dart';
import 'package:window_size/window_size.dart';

void main() async {
  await startApp();
}

Future<void> startApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  if (isDesktop) {
    setWindowTitle('Effektio');
  }
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('google_fonts/LICENSE.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
  Get.put(ScreenshotController());
  final sdk = await EffektioSdk.instance;
  PlatformDispatcher.instance.onError = (exception, stackTrace) {
    sdk.writeLog(exception.toString(), 'error');
    sdk.writeLog(stackTrace.toString(), 'error');
    return true; // make this error handled
  };
  runApp(const Effektio());
}

class Effektio extends StatelessWidget {
  const Effektio({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugInvertOversizedImages = true; // detect non-optimized images
    return Portal(
      child: Themed(
        child: OverlaySupport.global(
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
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/':
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (ctx) => const EffektioHome(),
                  );
                case '/login':
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (ctx) => const LoginPage(),
                  );
                case '/profile':
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (ctx) => const SocialProfilePage(),
                  );
                case '/signup':
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (ctx) => const SignupPage(),
                  );
                case '/gallery':
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (ctx) => const GalleryPage(),
                  );
                case '/bug_report':
                  return MaterialPageRoute(
                    settings: settings,
                    builder: (ctx) {
                      final map = settings.arguments as Map;
                      return BugReportPage(imagePath: map['screenshot']);
                    },
                  );
                default:
                  return null;
              }
            },
          ),
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
  late SyncState syncState;
  int tabIndex = 0;
  late TabController tabController;
  String? displayName;
  Future<FfiBufferUint8>? displayAvatar;

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

    syncState = client.startSync();
    //Start listening for cross signing events
    if (!client.isGuest()) {
      await client.groups().then(
        (groups) async {
          if (groups.toList().isEmpty) {
            // Create default effektio group when client synced.
            CreateGroupSettings settings = sdk.newGroupSettings(
              '${simplifyUserId(client.userId().toString())} Team',
            );
            settings.alias(UniqueKey().toString());
            settings.visibility('Public');
            settings.addInvitee('@sisko:matrix.org');
            await client.createEffektioGroup(settings);
          }
        },
      );
      await client.getUserProfile().then((value) {
        if (mounted) {
          setState(() {
            if (value.hasAvatar()) {
              displayAvatar = value.getThumbnail(50, 50);
            }
            displayName = value.getDisplayName();
          });
        }
      });
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
    return AppBar(
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
      child: const Tab(icon: Icon(FlutterIcons.pin_ent)),
    );
  }

  Widget buildTasksTab() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: const Tab(
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
    tabController.addListener(() {
      if (client.isGuest() && tabIndex == 3) {
        showNotYetImplementedMsg(
          context,
          'Chat for Guests is not implemented yet',
        );
      }
    });
    return DefaultTabController(
      length: 4,
      key: const Key('bottom-bar'),
      child: SafeArea(
        child: Screenshot(
          child: Scaffold(
            appBar: buildAppBar(),
            body: TabBarView(
              controller: tabController,
              children: [
                NewsPage(
                  client: client,
                  displayName: displayName,
                  displayAvatar: displayAvatar,
                ),
                FaqPage(client: client),
                ToDoPage(client: client),
                ChatPage(client: client),
              ],
            ),
            drawer: SideDrawer(
              isGuest: client.isGuest(),
              userId: client.userId().toString(),
              displayName: displayName,
              displayAvatar: displayAvatar,
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
                buildNewsFeedTab(),
                buildPinsTab(),
                buildTasksTab(),
                buildChatTab(),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                throw Exception('force exception');
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
        }
        if (snapshot.hasError) {
          return SizedBox(
            height: 40,
            width: 40,
            child: Text('${snapshot.error}'),
          );
        }
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
      },
    );
  }
}
