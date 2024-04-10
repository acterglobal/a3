import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class EmptyState extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final String image;
  final double imageSize;
  final Widget? primaryButton;
  final Widget? secondaryButton;

  const EmptyState({
    super.key,
    this.title,
    this.subtitle,
    required this.image,
    this.imageSize = 150,
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
            semanticsLabel: L10n.of(context).state,
            height: imageSize,
            width: imageSize,
          ),
          const SizedBox(
            height: 10,
          ),
          if (title != null)
            Text(
              title!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          const SizedBox(
            height: 10,
          ),
          if (subtitle != null)
            Text(
              subtitle!,
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
