import 'dart:async';

import 'package:flutter/material.dart';

import 'package:acter/models/onBoard.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  // Variables
  PageController _pageController = PageController(initialPage: 0);

  int _pageIndex = 0;
  Timer? _timer;

  // OnBoarding content list
  final List onBoardingPages = [
    OnBoarding(
      image: 'assets/images/spaces_onboard.png',
      title: RichText(
        textAlign: TextAlign.center,
        text: const TextSpan(
          text: 'Organise & Collaborate Through ',
          style: TextStyle(color: Colors.green, fontSize: 24),
          children: <TextSpan>[
            TextSpan(
              text: 'Spaces',
              style: TextStyle(
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
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Spaces',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 17
                  ),
                ),
                TextSpan(
                  text:
                      ' are the central point of your communities where chats, events, todos, updates, and resources are.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          const Text(
            'Gather people in one or multiple spaces & create your own organizational strutcure.',
            style: TextStyle(fontSize: 17, color: Colors.white),
          )
        ],
      ),
    ),
    OnBoarding(
      image: 'assets/images/comms_onboard.png',
      title: RichText(
        textAlign: TextAlign.center,
        text: const TextSpan(
          style: TextStyle(color: Colors.green),
          children: <TextSpan>[
            TextSpan(
              text: 'Communication',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
            TextSpan(
                text: ' without compromise.', style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
      description: Column(
        children: [
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Communicate and coordinate',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 17,
                  ),
                ),
                TextSpan(
                  text:
                      ' individually or acreoss endless organizations.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'End-to-end encrypted',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 17,
                  ),
                ),
                TextSpan(
                  text:
                      ' by default, no adds and no data mining.',
                  style: TextStyle(
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
        text: const TextSpan(
          text: 'Reduce noice & increase engagement with ',
          style: TextStyle(color: Colors.green, fontSize: 24,),
          children: <TextSpan>[
            TextSpan(
              text: 'updates',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
      description: RichText(
        text: const TextSpan(
          text: 'Enable people to ',
          style: TextStyle(color: Colors.white, fontSize: 17),
          children: <TextSpan>[
            TextSpan(
              text: 'see and engage with important updates',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 17),
            ),
            TextSpan(
                text: ', by separating them from casual conversations.',
                style: TextStyle(color: Colors.white, fontSize: 17)),
          ],
        ),
      ),
    ),
    OnBoarding(
      image: 'assets/images/modularity_onboard.png',
      title: RichText(
        textAlign: TextAlign.center,
        text: const TextSpan(
          style: TextStyle(color: Colors.green),
          children: <TextSpan>[
            TextSpan(
              text: 'Simple to use',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
            TextSpan(
                text: ' - add features as needed.',
                style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
      description: 
      RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Customize Acter',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 17,
                  ),
                ),
                TextSpan(
                  text:
                      ' to your needs as you grow from a small group into global movement of thousands.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Initialize page controller
    _pageController = PageController(initialPage: 0);
    // Automatic scroll behaviour
    // _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
    //   if (_pageIndex < 3) {
    //     _pageIndex++;
    //   } else {
    //     _pageIndex = 0;
    //   }

    //   _pageController.animateToPage(
    //     _pageIndex,
    //     duration: const Duration(milliseconds: 350),
    //     curve: Curves.easeIn,
    //   );
    // });
  }

  @override
  void dispose() {
    // Dispose everything
    _pageController.dispose();
    _timer!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      padding: const EdgeInsets.only(top: kToolbarHeight),
      // Background gradient
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
          stops: [0.2, 0.4, 0.6, 1.0],
          tileMode: TileMode.decal,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                  onPageChanged: (index) {
                    setState(() {
                      _pageIndex = index;
                    });
                  },
                  itemCount: onBoardingPages.length,
                  controller: _pageController,
                  itemBuilder: (context, index) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(
                          height: 2,
                        ),
                        onBoardingPages[index].title,
                        SizedBox(
                          height: 280,
                          child: Image.asset(
                            onBoardingPages[index].image,
                          ),
                        ),
                        onBoardingPages[index].description,
                        const SizedBox(
                          height: 20,
                        )
                      ],
                    );
                  }),
            ),
            GestureDetector(
              onTap: (){

              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16.0),
                    child: Text('Skip'),
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
                    onTap: (){
                      next();
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        children: const [
                          Text('Next'),
                          SizedBox(
                            width: 8,
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  void next(){
     if (_pageController.page! < onBoardingPages.length - 1) { 
      _pageController.nextPage(duration: Duration(seconds: 1),curve: Curves.ease,);
      
    } else {
      // Handle reaching the last screen
      // For example, you could navigate to the main part of your app
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => HomeScreen(),
      //   ),
      // );
    }
  }
}

// class OnBoardContent extends StatelessWidget {
//   OnBoardContent({
//     super.key,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return
//   }
// }

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
