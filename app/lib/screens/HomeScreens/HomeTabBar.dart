import 'package:effektio/common/store/Colors.dart';
import 'package:effektio/screens/HomeScreens/News.dart';
import 'package:effektio/screens/HomeScreens/Notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ignore: must_be_immutable
class HomeTabBar extends StatefulWidget {
  // ignore: use_key_in_widget_constructors
  HomeTabBar(this.selectedIndex);

  var selectedIndex = 0;

  @override
  _MyHomeTabBar createState() => _MyHomeTabBar();
}

class _MyHomeTabBar extends State<HomeTabBar> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    setState(() {
      _selectedIndex = widget.selectedIndex;
    });
  }

  static final List<Widget> _widgetOptions = <Widget>[
    const NewsScreen(),
    const NewsScreen(),
    const NewsScreen(),
    const NewsScreen(),
    const NotificationScreen()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !Navigator.of(context).userGestureInProgress,
      child: Scaffold(
        body: Center(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: AppColors.textFieldColor,
          type: BottomNavigationBarType.fixed,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Container(
                margin: const EdgeInsets.only(top: 10),
                child: SvgPicture.asset('assets/images/newsfeed_linear.svg'),
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
                child:
                    SvgPicture.asset('assets/images/notification_linear.svg'),
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
          currentIndex: _selectedIndex,
          showUnselectedLabels: true,
          selectedItemColor: AppColors.primaryColor,
          iconSize: 30,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
