// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'dart:async';
import 'package:effektio/common/store/separatedThemes.dart';
import 'package:effektio/common/store/appTheme.dart';
import 'package:effektio/common/widget/AppCommon.dart';
import 'package:effektio/common/widget/MaterialIndicator.dart';
import 'package:effektio/common/widget/SideMenu.dart';
import 'package:effektio/l10n/l10n.dart';
import 'package:effektio/screens/faq/Overview.dart';
import 'package:effektio/screens/HomeScreens/ChatList.dart';
import 'package:effektio/screens/HomeScreens/News.dart';
import 'package:effektio/screens/HomeScreens/Notification.dart';
import 'package:effektio/screens/OnboardingScreens/LogIn.dart';
import 'package:effektio/screens/OnboardingScreens/Signup.dart';
import 'package:effektio/screens/SideMenuScreens/Gallery.dart';
import 'package:effektio/screens/UserScreens/SocialProfile.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk.dart'
    show Client, EffektioSdk;
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show SyncState, CrossSigningEvent;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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
  runApp(
    Effektio(),
  );
}

class Effektio extends StatefulWidget {
  const Effektio({Key? key}) : super(key: key);

  @override
  State<Effektio> createState() => _EffektioState();
}

class _EffektioState extends State<Effektio> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Themed(
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        title: 'Effektio',
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: ApplicationLocalizations.supportedLocales,
        // MaterialApp contains our top-level Navigator
        initialRoute: '/',
        routes: <String, WidgetBuilder>{
          '/': (BuildContext context) => EffektioHome(),
          '/login': (BuildContext context) => const LoginScreen(),
          '/profile': (BuildContext context) => const SocialProfileScreen(),
          '/signup': (BuildContext context) => const SignupScreen(),
          '/gallery': (BuildContext context) => const GalleryScreen(),
        },
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
    with TickerProviderStateMixin {
  late Future<Client> _client;
  Stream<CrossSigningEvent>? _toDeviceRx;
  late StreamSubscription<CrossSigningEvent> _toDeviceSubscription;
  int tabIndex = 0;
  late TabController _tabController;
  bool isLoading = false;
  late bool waitForMatch;
  @override
  void initState() {
    _client = makeClient();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      setState(() {
        tabIndex = _tabController.index;
      });
    });
    super.initState();
  }

  Future<Client> makeClient() async {
    final sdk = await EffektioSdk.instance;
    Client client = await sdk.currentClient;
    SyncState syncer = client.startSync();
    // emoji verification
    _toDeviceRx = syncer.getToDeviceRx();
    _toDeviceSubscription = _toDeviceRx!.listen((event) async {
      String eventName = event.getEventName();
      String eventId = event.getEventId();
      String sender = event.getSender();
      waitForMatch = false;
      debugPrint(eventName);
      if (eventName == 'AnyToDeviceEvent::KeyVerificationRequest') {
        await onKeyVerificationRequest(sender, eventId);
      } else if (eventName == 'AnyToDeviceEvent::KeyVerificationReady') {
        await onKeyVerificationReady(sender, eventId);
      } else if (eventName == 'AnyToDeviceEvent::KeyVerificationStart') {
        await onKeyVerificationStart(sender, eventId);
      } else if (eventName == 'AnyToDeviceEvent::KeyVerificationCancel') {
        await onKeyVerificationCancel(sender, eventId);
      } else if (eventName == 'AnyToDeviceEvent::KeyVerificationAccept') {
        await onKeyVerificationAccept(sender, eventId);
      } else if (eventName == 'AnyToDeviceEvent::KeyVerificationKey') {
        await onKeyVerificationKey(sender, eventId);
      } else if (eventName == 'AnyToDeviceEvent::KeyVerificationMac') {
        await onKeyVerificationMac(sender, eventId);
      } else if (eventName == 'AnyToDeviceEvent::KeyVerificationDone') {
        await onKeyVerificationDone(sender, eventId);
        // clean up event listener
        Future.delayed(const Duration(seconds: 1), () {
          _toDeviceSubscription.cancel();
        });
      }
    });
    return client;
  }

  Future<void> onKeyVerificationRequest(String sender, String eventId) async {
    Completer<void> c = Completer();
    isLoading = false;
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              color: AppCommonTheme.darkShade,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      child: SvgPicture.asset(
                          'assets/images/baseline-devices.svg'),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Verification Request',
                      style: AppCommonTheme.appBartitleStyle
                          .copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          Get.back();
                        },
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    text: 'Verification Requested from ',
                    style: AppCommonTheme.appBartitleStyle
                        .copyWith(fontSize: 14, fontWeight: FontWeight.w400),
                    children: <TextSpan>[
                      TextSpan(
                        text: sender,
                        style: AppCommonTheme.appBartitleStyle.copyWith(
                          color: AppCommonTheme.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                SvgPicture.asset(
                  'assets/images/lock.svg',
                  width: MediaQuery.of(context).size.width * 0.2,
                  height: MediaQuery.of(context).size.height * 0.2,
                ),
                const SizedBox(height: 15),
                isLoading
                    ? SizedBox(
                        child: SizedBox(
                          child: CircularProgressIndicator(
                            color: AppCommonTheme.primaryColor,
                          ),
                        ),
                      )
                    : elevatedButton(
                        'Start Verifying',
                        AppCommonTheme.greenButtonColor,
                        () => {
                          setState(() {
                            isLoading = true;
                          }),
                          onKeyVerificationReady(sender, eventId),
                          c.complete()
                        },
                        AppCommonTheme.appBartitleStyle.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
    return c.future;
  }

  Future<void> onKeyVerificationReady(String sender, String eventId) async {
    var client = await _client;
    await client.acceptVerificationRequest(sender, eventId);
  }

  Future<void> onKeyVerificationStart(String sender, String eventId) async {
    isLoading = false;
    Get.back();
    Completer<void> c = Completer();
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          color: AppCommonTheme.darkShade,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10.0),
                  child: SvgPicture.asset(
                    'assets/images/baseline-devices.svg',
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Verify your new session',
                  style: AppCommonTheme.appBartitleStyle
                      .copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      Get.back();
                    },
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                'Scan the QR code below to Verify',
                style: AppCommonTheme.appBartitleStyle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppCommonTheme.dividerColor,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(25.0),
                child: SizedBox(
                  height: 100,
                  width: 100,
                  child: CircularProgressIndicator(
                    color: AppCommonTheme.dividerColor,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SvgPicture.asset(
                      'assets/images/camera.svg',
                      color: AppCommonTheme.primaryColor,
                      height: 14,
                      width: 14,
                    ),
                  ),
                  Text(
                    'Scan other code/device',
                    style: AppCommonTheme.appBartitleStyle.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppCommonTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: RichText(
                textAlign: TextAlign.center,
                softWrap: true,
                text: TextSpan(
                  text:
                      'If this wasn\'t you, your account may be compromised. Manage your security in ',
                  style: AppCommonTheme.appBartitleStyle.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppCommonTheme.dividerColor,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'Settings',
                      style: AppCommonTheme.appBartitleStyle.copyWith(
                        color: AppCommonTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () async {
                  var client = await _client;
                  await client.acceptVerificationStart(sender, eventId);
                  Get.back();
                  c.complete();
                },
                child: Text(
                  'Can\'t Scan',
                  style: AppCommonTheme.appBartitleStyle.copyWith(
                    color: AppCommonTheme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      isDismissible: false,
    );
    return c.future;
  }

  Future<void> onKeyVerificationCancel(String sender, String eventId) async {}

  Future<void> onKeyVerificationAccept(String sender, String eventId) async {}

  Future<void> onKeyVerificationKey(String sender, String eventId) async {
    Completer<void> c = Completer();
    var client = await _client;
    List<int> emoji = await client.getVerificationEmoji(sender, eventId);
    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              color: AppCommonTheme.darkShade,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      child: SvgPicture.asset(
                        'assets/images/baseline-devices.svg',
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Verify by Emoji',
                      style: AppCommonTheme.appBartitleStyle
                          .copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          Get.back();
                        },
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                  child: Text(
                    'Confirm the unique emoji appears on the other session, that are in the same order',
                    style: AppCommonTheme.appBartitleStyle.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppCommonTheme.dividerColor,
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    height: MediaQuery.of(context).size.height * 0.28,
                    width: MediaQuery.of(context).size.width * 0.90,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15.0),
                      color: AppCommonTheme.backgroundColor,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: GridView.count(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10.0,
                        children: List.generate(emoji.length, (index) {
                          return GridTile(
                            child: Text(
                              String.fromCharCode(emoji[index]),
                              style: TextStyle(fontSize: 32),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5.0),
                waitForMatch
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Text(
                            'Waiting for match...',
                            style: AppCommonTheme.appBartitleStyle.copyWith(
                              color: AppCommonTheme.dividerColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.only(left: 20),
                            width: MediaQuery.of(context).size.width * 0.48,
                            child: elevatedButton(
                              'They don\'t match',
                              AppCommonTheme.primaryColor,
                              () async {
                                var client = await _client;
                                await client.mismatchVerificationKey(
                                  sender,
                                  eventId,
                                );
                                Get.back();
                                c.complete();
                              },
                              AppCommonTheme.appBartitleStyle.copyWith(
                                  fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(width: 5.0),
                          Container(
                            padding: const EdgeInsets.only(right: 20),
                            width: MediaQuery.of(context).size.width * 0.48,
                            child: elevatedButton(
                              'They match',
                              AppCommonTheme.greenButtonColor,
                              () async {
                                setState(() {
                                  waitForMatch = true;
                                });
                                await onKeyVerificationMac(sender, eventId);
                                client.confirmVerificationKey(sender, eventId);
                                Get.back();
                                c.complete();
                              },
                              AppCommonTheme.appBartitleStyle.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                Center(
                  child: TextButton(
                    onPressed: () async {},
                    child: Text(
                      'QR Scan Instead',
                      style: AppCommonTheme.appBartitleStyle.copyWith(
                        color: AppCommonTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    return c.future;
  }

  Future<void> onKeyVerificationMac(String sender, String eventId) async {
    var client = await _client;
    await client.reviewVerificationMac(sender, eventId);
  }

  Future<void> onKeyVerificationDone(String sender, String eventId) async {
    Get.back();
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          color: AppCommonTheme.darkShade,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10.0),
                  child: SvgPicture.asset(
                    'assets/images/baseline-devices.svg',
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Verified',
                  style: AppCommonTheme.appBartitleStyle
                      .copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      Get.back();
                    },
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
              child: Text(
                'You can now read secure messages on your new device, and other users will know they can trust it.',
                style: AppCommonTheme.appBartitleStyle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppCommonTheme.dividerColor,
                ),
              ),
            ),
            const SizedBox(height: 15.0),
            Center(
              child: SvgPicture.asset(
                'assets/images/lock.svg',
                width: MediaQuery.of(context).size.width * 0.2,
                height: MediaQuery.of(context).size.height * 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget homeScreen(BuildContext context, Client client) {
    List<String?> _titles = <String?>[
      null,
      'FAQ',
      null,
      null,
      'Chat',
      'Notifications'
    ];

    return DefaultTabController(
      length: 5,
      key: const Key('bottom-bar'),
      child: SafeArea(
        child: Scaffold(
          appBar: tabIndex <= 3
              ? null
              : AppBar(
                  title: navBarTitle(_titles[tabIndex] ?? ''),
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
                        tooltip: MaterialLocalizations.of(context)
                            .openAppDrawerTooltip,
                      );
                    },
                  ),
                  actions: [
                    IconButton(
                      icon: Container(
                        margin: const EdgeInsets.only(bottom: 10, right: 10),
                        child: Icon(Icons.search),
                      ),
                      onPressed: () {},
                    )
                  ],
                ),
          body: TabBarView(
            controller: _tabController,
            children: [
              NewsScreen(
                client: client,
              ),
              FaqOverviewScreen(client: client),
              NewsScreen(
                client: client,
              ),
              ChatList(client: _client),
              NotificationScreen(),
            ],
          ),
          drawer: SideDrawer(
            client: _client,
          ),
          bottomNavigationBar: TabBar(
            labelColor: AppCommonTheme.primaryColor,
            unselectedLabelColor: AppCommonTheme.svgIconColor,
            controller: _tabController,
            indicator: MaterialIndicator(
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
              Container(
                margin: EdgeInsets.only(top: 10),
                child: Tab(
                  icon: tabIndex == 0
                      ? SvgPicture.asset(
                          'assets/images/newsfeed_bold.svg',
                        )
                      : SvgPicture.asset(
                          'assets/images/newsfeed_linear.svg',
                        ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 10),
                child: Tab(
                  icon: tabIndex == 1
                      ? SvgPicture.asset(
                          'assets/images/menu_bold.svg',
                        )
                      : SvgPicture.asset(
                          'assets/images/menu_linear.svg',
                        ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 10),
                child: Tab(
                  icon: tabIndex == 2
                      ? SvgPicture.asset(
                          'assets/images/add.svg',
                          color: AppCommonTheme.primaryColor,
                        )
                      : SvgPicture.asset(
                          'assets/images/add.svg',
                        ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 10),
                child: Tab(
                  icon: tabIndex == 3
                      ? SvgPicture.asset(
                          'assets/images/chat_bold.svg',
                        )
                      : SvgPicture.asset(
                          'assets/images/chat_linear.svg',
                        ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 10),
                child: Tab(
                  icon: tabIndex == 4
                      ? SvgPicture.asset(
                          'assets/images/notification_bold.svg',
                        )
                      : SvgPicture.asset(
                          'assets/images/notification_linear.svg',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Client>(
      future: _client, // a previously-obtained Future<String> or null
      builder: (BuildContext context, AsyncSnapshot<Client> snapshot) {
        if (snapshot.hasData) {
          return homeScreen(context, snapshot.requireData);
        } else {
          return Scaffold(
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
