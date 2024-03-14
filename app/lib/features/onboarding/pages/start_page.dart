import 'dart:math';

import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/models/onBoard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  // Variables
  final PageController _pageController = PageController(initialPage: 0);

  int _pageIndex = 0;

  // OnBoarding content list
  List onBoardingPages = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    onBoardingPages = [
      OnBoarding(
        image: 'assets/images/spaces_onboard.png',
        title: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: L10n.of(context).onBoardingSpaceTitle('title1'),
            style: const TextStyle(color: Colors.green, fontSize: 24),
            children: <TextSpan>[
              TextSpan(
                text: L10n.of(context).onBoardingSpaceTitle('title2'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
        description: Column(
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: L10n.of(context).onBoardingSpaceDescription('desc1'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 17,
                    ),
                  ),
                  TextSpan(
                    text: L10n.of(context).onBoardingSpaceDescription('desc2'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            Text(
              L10n.of(context).onBoardingSpaceDescription('desc3'),
              style: const TextStyle(fontSize: 17, color: Colors.white),
            ),
          ],
        ),
      ),
      OnBoarding(
        image: 'assets/images/comms_onboard.png',
        title: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(color: Colors.green),
            children: <TextSpan>[
              TextSpan(
                text: L10n.of(context).onBoardingCommunicationTitle('title1'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
              TextSpan(
                text: L10n.of(context).onBoardingCommunicationTitle('title2'),
                style: const TextStyle(fontSize: 24),
              ),
            ],
          ),
        ),
        description: Column(
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: L10n.of(context)
                        .onBoardingCommunicationDescription('desc1'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 17,
                    ),
                  ),
                  TextSpan(
                    text: L10n.of(context)
                        .onBoardingCommunicationDescription('desc2'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: L10n.of(context)
                        .onBoardingCommunicationDescription('desc3'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 17,
                    ),
                  ),
                  TextSpan(
                    text: L10n.of(context)
                        .onBoardingCommunicationDescription('desc4'),
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
      ),
      OnBoarding(
        image: 'assets/images/update_onboard.png',
        title: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: L10n.of(context).onBoardingUpdateTitle('title1'),
            style: const TextStyle(
              color: Colors.green,
              fontSize: 24,
            ),
            children: <TextSpan>[
              TextSpan(
                text: L10n.of(context).onBoardingUpdateTitle('title2'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
        description: RichText(
          text: TextSpan(
            text: L10n.of(context).onBoardingUpdateDescription('desc1'),
            style: const TextStyle(color: Colors.white, fontSize: 17),
            children: <TextSpan>[
              TextSpan(
                text: L10n.of(context).onBoardingUpdateDescription('desc2'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 17,
                ),
              ),
              TextSpan(
                text: L10n.of(context).onBoardingUpdateDescription('desc3'),
                style: const TextStyle(color: Colors.white, fontSize: 17),
              ),
            ],
          ),
        ),
      ),
      OnBoarding(
        image: 'assets/images/modularity_onboard.png',
        title: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(color: Colors.green),
            children: <TextSpan>[
              TextSpan(
                text: L10n.of(context).onBoardingSimpleToUseTitle('title1'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
              TextSpan(
                text: L10n.of(context).onBoardingSimpleToUseTitle('title2'),
                style: const TextStyle(fontSize: 24),
              ),
            ],
          ),
        ),
        description: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text:
                    L10n.of(context).onBoardingSimpleToUseDescription('desc1'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 17,
                ),
              ),
              TextSpan(
                text:
                    L10n.of(context).onBoardingSimpleToUseDescription('desc2'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageHeight =
        min(MediaQuery.of(context).size.height * 0.45, 280).toDouble();
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        padding: const EdgeInsets.only(top: kToolbarHeight),
        decoration: const BoxDecoration(
          gradient: introGradient,
        ),
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                onPageChanged: (index) {
                  if (mounted) {
                    setState(() => _pageIndex = index);
                  }
                },
                itemCount: onBoardingPages.length,
                controller: _pageController,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(
                          height: 2,
                        ),
                        onBoardingPages[index].title,
                        SizedBox(
                          height: imageHeight,
                          child: Image.asset(
                            onBoardingPages[index].image,
                          ),
                        ),
                        SizedBox(
                          child: FittedBox(
                            child: onBoardingPages[index].description,
                            fit: BoxFit.scaleDown,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            GestureDetector(
              onTap: () => context.goNamed(Routes.introProfile.name),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      key: Keys.skipBtn,
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(L10n.of(context).skip),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ...List.generate(
                            onBoardingPages.length,
                            (index) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: DotIndicator(
                                isActive: index == _pageIndex,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        next();
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          children: [
                            Text(L10n.of(context).next),
                            const SizedBox(
                              width: 8,
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void next() {
    if (_pageController.page! < onBoardingPages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(seconds: 1),
        curve: Curves.ease,
      );
    } else {
      context.pushNamed(Routes.introProfile.name);
    }
  }
}

// Dot indicator widget
class DotIndicator extends StatelessWidget {
  const DotIndicator({
    this.isActive = false,
    super.key,
  });

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 9,
      width: 9,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.transparent,
        border: isActive ? null : Border.all(color: Colors.white),
        borderRadius: const BorderRadius.all(
          Radius.circular(12),
        ),
      ),
    );
  }
}
