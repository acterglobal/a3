import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_onboarding_slider/flutter_onboarding_slider.dart';
import 'package:go_router/go_router.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: OnBoardingSlider(
        headerBackgroundColor: Colors.white,
        centerBackground: true,
        finishButtonText: 'Register',
        finishButtonStyle: const FinishButtonStyle(
          backgroundColor: Colors.black,
        ),
        onFinish: () => context.pushNamed(Routes.authRegister.name),
        skipTextButton: const Text('Skip', key: Keys.skipBtn),
        trailing: InkWell(
          child: const Text('Login', key: Keys.loginBtn),
          onTap: () => context.pushNamed(Routes.authLogin.name),
        ),
        background: [
          Image.asset('assets/images/onboarding-welcome.png'),
          Image.asset('assets/images/onboarding-collaboration.png'),
          Image.asset('assets/images/onboarding-train-station.png'),
        ],
        totalPage: 3,
        speed: 1.8,
        pageBodies: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: const <Widget>[
                SizedBox(height: 480),
                Text('Welcome to acter'),
                Text('Team. Team. Team.'),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: const <Widget>[
                SizedBox(height: 480),
                Text('Get organized. Together.'),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: const <Widget>[
                SizedBox(height: 480),
                Text('From anywhere. Any time. Mobile first'),
              ],
            ),
          ),
        ],
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
