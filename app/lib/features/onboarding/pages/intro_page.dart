import 'package:acter/common/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final List<String> introTexts = [
    'Simple to use.',
    'Secure with E2E Encryption.',
    'Powerful for any organiser.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
           gradient: LinearGradient(
          colors: [
            Color(0xff121F2B),
            Color(0xff122334),
            Color(0xff121315),
            Color(0xff121315),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.6, 0.8, 1.0],
          tileMode: TileMode.decal,
        ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: kToolbarHeight),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 15),
                    height: 100,
                    width: 100,
                    child: Image.asset('assets/icon/logo_foreground.png'),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 15),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        text: 'Welcome to',
                        style: TextStyle(color: Colors.white, fontSize: 32),
                        children: <TextSpan>[
                          TextSpan(
                            text: ' Acter!',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 32,),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 35),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          child: const Text(
                            'A powerful and secure app for organising change.',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 20),
                          height: 100,
                          child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: introTexts.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: const EdgeInsets.only(top: 5),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.circle,
                                        color: Colors.white,
                                        size: 8,
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                              text: introTexts[index]
                                                      .split(' ')[0] +
                                                  ' ',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                                fontSize: 17,
                                              ),
                                            ),
                                            TextSpan(
                                              text: introTexts[index].substring(
                                                introTexts[index].indexOf(' ') +
                                                    1,
                                              ),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 17,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                );
                              },),
                        ),
                        GestureDetector(
                          onTap: () => context.goNamed(Routes.start.name),
                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                                child: Text(
                              "Let's get started",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,),
                            ),),
                          ),
                        )
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
