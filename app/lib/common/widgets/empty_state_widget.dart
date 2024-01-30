import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String image;
  final Widget? primaryButton;
  final Widget? secondaryButton;

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.image,
    this.primaryButton,
    this.secondaryButton,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            image,
            semanticsLabel: 'state',
            height: 150,
            width: 150,
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(
            height: 10,
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(
            height: 10,
          ),
          if (primaryButton != null) primaryButton!,
          const SizedBox(
            height: 10,
          ),
          if (secondaryButton != null) secondaryButton!,
        ],
      ),
    );
  }
}
