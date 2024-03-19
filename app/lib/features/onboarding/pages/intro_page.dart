import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  List<String> introTexts = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    introTexts = [
      L10n.of(context).simpleToUse,
      L10n.of(context).secureWithE2EEncryption,
      L10n.of(context).powerfulForAnyOrganizer,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: introGradient,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const SizedBox(height: 80),
            Image.asset(
              'assets/icon/logo_foreground.png',
              height: 100,
              width: 100,
            ),
            const SizedBox(height: 20),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                text: L10n.of(context).welcomeTo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: ' ${L10n.of(context).acter}!',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 32,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              L10n.of(context).aPowerfulAndSecureApp,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: introTexts.length,
              shrinkWrap: true,
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
                              text: '${introTexts[index].split(' ')[0]} ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 17,
                              ),
                            ),
                            TextSpan(
                              text: introTexts[index].substring(
                                introTexts[index].indexOf(' ') + 1,
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => context.goNamed(Routes.start.name),
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    L10n.of(context).letsGetStarted,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
