// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:effektio/common/store/Colors.dart';
import 'package:effektio/common/widget/AppCommon.dart';
import 'package:effektio/common/widget/SideMenu.dart';
import 'package:effektio/repository/client.dart';
import 'package:effektio/screens/HomeScreens/ChatList.dart';
import 'package:effektio/screens/HomeScreens/News.dart';
import 'package:effektio/screens/HomeScreens/Notification.dart';
import 'package:effektio/screens/OnboardingScreens/LogIn.dart';
import 'package:effektio/screens/OnboardingScreens/Signup.dart';
import 'package:effektio/screens/SideMenuScreens/Gallery.dart';
import 'package:effektio/screens/UserScreens/SocialProfile.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:effektio/l10n/l10n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Effektio(),
    ),
  );
}

class Effektio extends StatelessWidget {
  const Effektio({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //To avoid redundancy, the whole textTheme of app is setup as Montserrat,
      //so we can avoid using it explicitly in every Text Widget
      theme: ThemeData(
        textTheme: GoogleFonts.montserratTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
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
    );
  }
}

class EffektioHome extends StatefulWidget {
  const EffektioHome({Key? key}) : super(key: key);

  @override
  _EffektioHomeState createState() => _EffektioHomeState();
}

class _EffektioHomeState extends State<EffektioHome> {
  late Future<Client> _client;
  int tabIndex = 0;
  @override
  void initState() {
    super.initState();
    _client = makeClient();
  }

  String _navBarTitle(int index) {
    if (index == 0) {
      return 'News';
    } else if (index == 1) {
      return 'News';
    } else if (index == 2) {
      return 'News';
    } else if (index == 3) {
      return 'Chat';
    } else {
      return 'Nofitications';
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _widgetOptions = <Widget>[
      NewsScreen(
        client: _client,
      ),
      NewsScreen(
        client: _client,
      ),
      NewsScreen(
        client: _client,
      ),
      ChatList(client: _client),
      NotificationScreen(),
    ];
    return DefaultTabController(
      length: 5,
      child: SafeArea(
        child: Scaffold(
          appBar: tabIndex <= 3
              ? null
              : AppBar(
                  title: navBarTitle(_navBarTitle(tabIndex)),
                  centerTitle: true,
                  primary: false,
                  elevation: 1,
                  backgroundColor: AppColors.textFieldColor,
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
                        child: Image.asset('assets/images/search.png'),
                      ),
                      onPressed: () {
                        setState(() {});
                      },
                    )
                  ],
                ),
          body: _widgetOptions.elementAt(tabIndex),
          drawer: SideDrawer(
            client: _client,
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Color.fromRGBO(36, 38, 50, 1),
              boxShadow: [
                BoxShadow(color: Colors.grey, offset: Offset(0, -0.5)),
              ],
            ),
            child: BottomNavigationBar(
              backgroundColor: Color.fromRGBO(36, 38, 50, 1),
              type: BottomNavigationBarType.fixed,
              items: <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Container(
                    margin: const EdgeInsets.only(top: 10),
                    child:
                        SvgPicture.asset('assets/images/newsfeed_linear.svg'),
                  ),
                  activeIcon: Container(
                    margin: const EdgeInsets.only(top: 10),
                    child: SvgPicture.asset(
                      'assets/images/newsfeed_bold.svg',
                    ),
                  ),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    margin: const EdgeInsets.only(top: 10),
                    child: SvgPicture.asset('assets/images/menu_linear.svg'),
                  ),
                  activeIcon: Container(
                    margin: const EdgeInsets.only(top: 10),
                    child: SvgPicture.asset(
                      'assets/images/menu_bold.svg',
                    ),
                  ),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    margin: const EdgeInsets.only(top: 10),
                    child: SvgPicture.asset('assets/images/add.svg'),
                  ),
                  activeIcon: Container(
                    margin: const EdgeInsets.only(top: 10),
                    child: SvgPicture.asset(
                      'assets/images/add.svg',
                      color: AppColors.primaryColor,
                    ),
                  ),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    margin: const EdgeInsets.only(top: 10),
                    child: SvgPicture.asset('assets/images/chat_linear.svg'),
                  ),
                  activeIcon: Container(
                    margin: const EdgeInsets.only(top: 10),
                    child: SvgPicture.asset(
                      'assets/images/chat_bold.svg',
                    ),
                  ),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Container(
                    margin: const EdgeInsets.only(top: 10),
                    child: SvgPicture.asset(
                      'assets/images/notification_linear.svg',
                    ),
                  ),
                  activeIcon: Container(
                    margin: const EdgeInsets.only(top: 10),
                    child: SvgPicture.asset(
                      'assets/images/notification_bold.svg',
                    ),
                  ),
                  label: '',
                ),
              ],
              currentIndex: tabIndex,
              showUnselectedLabels: true,
              selectedItemColor: AppColors.primaryColor,
              iconSize: 30,
              onTap: (value) {
                setState(() {
                  tabIndex = value;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
