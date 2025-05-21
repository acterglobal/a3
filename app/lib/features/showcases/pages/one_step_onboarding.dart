import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';

typedef ChildBuilder = Widget Function(Function() onCallNext);

class _AllDoneWidget extends StatelessWidget {
  final Function() reset;
  const _AllDoneWidget({super.key, required this.reset});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: Center(
      heightFactor: 1.5,
      child: Column(
        children: [
          EmptyState(
            title: 'Success',
            subtitle: 'all done',
            image: 'assets/images/empty_activity.svg',
          ),
          ElevatedButton(onPressed: reset, child: Text('Reset')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Done'),
          ),
        ],
      ),
    ),
  );
}

class OneStepOnboardingPage extends StatefulWidget {
  final ChildBuilder builder;
  const OneStepOnboardingPage({super.key, required this.builder});

  @override
  State<OneStepOnboardingPage> createState() => _OneStepOnboardingPageState();
}

class _OneStepOnboardingPageState extends State<OneStepOnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late List<Widget> _screens;
  @override
  void initState() {
    super.initState();
    _screens = [
      widget.builder(_nextPage),
      _AllDoneWidget(
        reset: () {
          _pageController.jumpToPage(0);
          setState(() {
            _currentPage = 0;
          });
        },
      ),
    ];
  }

  void _nextPage() {
    if (_currentPage < _screens.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      onPageChanged: (index) => setState(() => _currentPage = index),
      children: _screens,
    ),
  );
}
