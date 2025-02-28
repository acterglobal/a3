import 'package:flutter/material.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_svg/svg.dart';

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
    final aTitle = title;
    final aSubtitle = subtitle;
    final aPrimaryButton = primaryButton;
    final aSecondaryButton = secondaryButton;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              image,
              semanticsLabel: L10n.of(context).state,
              height: imageSize,
              width: imageSize,
            ),
            const SizedBox(height: 10),
            if (aTitle != null)
              Text(aTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            if (aSubtitle != null)
              Text(
                aSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 10),
            if (aPrimaryButton != null) aPrimaryButton,
            const SizedBox(height: 10),
            if (aSecondaryButton != null) aSecondaryButton,
          ],
        ),
      ),
    );
  }
}
