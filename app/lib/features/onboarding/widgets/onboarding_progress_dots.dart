import 'package:flutter/material.dart';

class OnboardingProgressDots extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const OnboardingProgressDots({
    super.key,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) => _buildDot(index, context)),
    );
  }

  Widget _buildDot(int index, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
        currentPage == index ? Theme.of(context).primaryColor : Colors.grey,
      ),
    );
  }
}
