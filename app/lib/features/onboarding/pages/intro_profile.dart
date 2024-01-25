import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class IntroProfile extends StatefulWidget {
  const IntroProfile({super.key});

  @override
  State<IntroProfile> createState() => _IntroProfileState();
}

class _IntroProfileState extends State<IntroProfile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: introGradient,
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: kToolbarHeight),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 19),
                    height: 100,
                    width: 100,
                    child: Image.asset('assets/icon/logo_foreground.png'),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          child: const Text(
                            'Acter',
                            style: TextStyle(color: Colors.white, fontSize: 32),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          child: const Text(
                            'Ready to start organizing and collaborating in safe space?',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          child: const Text(
                            'Log in or create a new profile and start organizing!',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 10,
                    ),
                    child: Column(
                      children: [
                        ElevatedButton(
                          key: LoginPageKeys.signUpBtn,
                          onPressed: () =>
                              context.pushNamed(Routes.authRegister.name),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Create Profile'),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_forward_ios, size: 18),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 25,
                        ),
                        OutlinedButton(
                          key: Keys.loginBtn,
                          onPressed: () =>
                              context.pushNamed(Routes.authLogin.name),
                          child: const Center(
                            child: Text('Log in'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
