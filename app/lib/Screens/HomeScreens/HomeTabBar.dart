import 'package:effektio/common/store/Colors.dart';
import 'package:effektio/Screens/HomeScreens/News.dart';
import 'package:effektio/Screens/HomeScreens/Notification.dart';
import 'package:flutter/material.dart';

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
                child: Image.asset('assets/images/News.png'),
              ),
              activeIcon: Container(
                margin: const EdgeInsets.only(top: 10),
                child: Image.asset(
                  'assets/images/News.png',
                  color: AppColors.primaryColor,
                ),
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Container(
                margin: const EdgeInsets.only(top: 10),
                child: Image.asset('assets/images/feed.png'),
              ),
              activeIcon: Container(
                margin: const EdgeInsets.only(top: 10),
                child: Image.asset(
                  'assets/images/feed.png',
                  color: AppColors.primaryColor,
                ),
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Container(
                margin: const EdgeInsets.only(top: 10),
                child: Image.asset('assets/images/add.png'),
              ),
              activeIcon: Container(
                margin: const EdgeInsets.only(top: 10),
                child: Image.asset(
                  'assets/images/add.png',
                  color: AppColors.primaryColor,
                ),
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Container(
                margin: const EdgeInsets.only(top: 10),
                child: Image.asset('assets/images/chat.png'),
              ),
              activeIcon: Container(
                margin: const EdgeInsets.only(top: 10),
                child: Image.asset(
                  'assets/images/chat.png',
                  color: AppColors.primaryColor,
                ),
              ),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Container(
                margin: const EdgeInsets.only(top: 10),
                child: Image.asset('assets/images/bell.png'),
              ),
              activeIcon: Container(
                margin: const EdgeInsets.only(top: 10),
                child: Image.asset(
                  'assets/images/bell.png',
                  color: AppColors.primaryColor,
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
