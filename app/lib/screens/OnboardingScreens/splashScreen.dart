// ignore_for_file: prefer_const_constructors

import 'package:effektio/blocs/splash_screen/splash_screen_bloc.dart';
import 'package:effektio/common/store/Colors.dart';
import 'package:effektio/common/widget/splashScreenWidget.dart';
import 'package:effektio/main.dart';
import 'package:effektio/screens/OnboardingScreens/LogIn.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// This the widget where the BLoC states and events are handled.
class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(context),
    );
  }

  BlocProvider<SplashScreenBloc> _buildBody(BuildContext context) {
    return BlocProvider(
      create: (context) => SplashScreenBloc(),
      child: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        color: AppColors.backgroundColor,
        child: Center(
          child: BlocBuilder<SplashScreenBloc, SplashScreenState>(
            builder: (context, state) {
              if ((state is Initial) || (state is Loading)) {
                return SplashScreenWidget();
              } else if (state is Loaded) {
                return Effektio();
              } else {
                throw (e) {};
              }
            },
          ),
        ),
      ),
    );
  }
}
