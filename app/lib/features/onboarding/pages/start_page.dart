import 'package:acter/common/themes/app_theme.dart';
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

  void initData() {
    onBoardingPages = [
      OnBoarding(
        image: 'assets/images/spaces_onboard.png',
        title: Text(
          L10n.of(context).onBoardingSpaceTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.textHighlight,
              ),
        ),
        description: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              TextSpan(
                text: L10n.of(context).onBoardingSpaceDescription1,
              ),
              TextSpan(
                text: L10n.of(context).onBoardingSpaceDescription2,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context).colorScheme.textHighlight,
                    ),
              ),
              TextSpan(
                text: L10n.of(context).onBoardingSpaceDescription3,
              ),
            ],
          ),
        ),
      ),
      OnBoarding(
        image: 'assets/images/comms_onboard.png',
        title: Text(
          L10n.of(context).onBoardingCommunicationTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.textHighlight,
              ),
        ),
        description: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              TextSpan(
                text: L10n.of(context).onBoardingCommunicationDescription1,
              ),
              TextSpan(
                text: L10n.of(context).onBoardingCommunicationDescription2,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context).colorScheme.textHighlight,
                    ),
              ),
              TextSpan(
                text: L10n.of(context).onBoardingCommunicationDescription3,
              ),
            ],
          ),
        ),
      ),
      OnBoarding(
        image: 'assets/images/update_onboard.png',
        title: Text(
          L10n.of(context).onBoardingUpdateTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.textHighlight,
              ),
        ),
        description: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              TextSpan(
                text: L10n.of(context).onBoardingUpdateDescription1,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context).colorScheme.textHighlight,
                    ),
              ),
              TextSpan(
                text: L10n.of(context).onBoardingUpdateDescription2,
              ),
            ],
          ),
        ),
      ),
      OnBoarding(
        image: 'assets/images/modularity_onboard.png',
        title: Text(
          L10n.of(context).onBoardingSimpleToUseTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.textHighlight,
              ),
        ),
        description: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              TextSpan(
                text: L10n.of(context).onBoardingSimpleToUseDescription1,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context).colorScheme.textHighlight,
                    ),
              ),
              TextSpan(
                text: L10n.of(context).onBoardingSimpleToUseDescription2,
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
    initData();
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: kToolbarHeight),
      decoration: const BoxDecoration(
        gradient: introGradient,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              _buildPageView(),
              _buildBottomButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageView() {
    return Expanded(
      child: PageView.builder(
        onPageChanged: (index) {
          if (mounted) {
            setState(() => _pageIndex = index);
          }
        },
        itemCount: onBoardingPages.length,
        controller: _pageController,
        itemBuilder: (context, index) {
          return _buildPageViewItem(index);
        },
      ),
    );
  }

  Widget _buildPageViewItem(int index) {
    final imageSize = MediaQuery.of(context).size.height / 4;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          onBoardingPages[index].title,
          const Spacer(),
          Image.asset(
            onBoardingPages[index].image,
            height: imageSize,
            width: imageSize,
          ),
          const Spacer(),
          onBoardingPages[index].description,
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            key: Keys.skipBtn,
            onTap: () => context.goNamed(Routes.introProfile.name),
            child: Text(L10n.of(context).skip),
          ),
          Row(
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
          GestureDetector(
            onTap: () => next(),
            child: Row(
              children: [
                Text(L10n.of(context).next),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
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
        color: isActive
            ? Theme.of(context).colorScheme.textColor
            : Colors.transparent,
        border: isActive
            ? null
            : Border.all(color: Theme.of(context).colorScheme.textColor),
        borderRadius: const BorderRadius.all(
          Radius.circular(12),
        ),
      ),
    );
  }
}
