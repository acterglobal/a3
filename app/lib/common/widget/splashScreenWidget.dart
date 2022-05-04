// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:effektio/blocs/splash_screen/splash_screen_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreenWidget extends StatefulWidget {
  const SplashScreenWidget({Key? key}) : super(key: key);

  @override
  _SplashScreenWidgetState createState() => _SplashScreenWidgetState();
}

class _SplashScreenWidgetState extends State<SplashScreenWidget> {
  // ignore: unused_field
  bool flag = false;
  @override
  void initState() {
    super.initState();
    _changeLogo();
    _dispatchEvent(
      context,
    ); // This will dispatch the navigateToHomeScreen event.
  }

  void _changeLogo() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      flag = !flag;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: sized_box_for_whitespace
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Center(
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 800),
                child: !flag
                    ? SizedBox(
                        key: Key('1'),
                        height: MediaQuery.of(context).size.height / 5,
                        width: MediaQuery.of(context).size.width / 5,
                        child: SvgPicture.asset('assets/images/logo.svg'),
                      )
                    : SizedBox(
                        key: Key('2'),
                        height: MediaQuery.of(context).size.height / 1.5,
                        width: MediaQuery.of(context).size.width / 1.5,
                        child: SvgPicture.asset('assets/images/main_logo.svg'),
                      ),
                switchInCurve: Curves.ease,
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final inAnimation = Tween<Offset>(
                    begin: Offset(-1.0, 0.0),
                    end: Offset(0.0, 0.0),
                  ).animate(animation);
                  return SlideTransition(
                    position: inAnimation,
                    child: child,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  //This method will dispatch the navigateToHomeScreen event.
  void _dispatchEvent(BuildContext context) {
    BlocProvider.of<SplashScreenBloc>(context).add(
      NavigateToHomeScreenEvent(),
    );
  }
}
