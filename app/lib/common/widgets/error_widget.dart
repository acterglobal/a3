import 'package:flutter/material.dart';

class ErrorWidgetTemplate extends StatelessWidget {
  final String title;
  final String subtitle;
  final String image;
  final Widget? primaryButton;
  final Widget? secondaryButton;

  const ErrorWidgetTemplate({
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
          SizedBox(
            height: 150,
            child: Image.asset(
              image,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Text(title,style: Theme.of(context).textTheme.titleSmall,),
          const SizedBox(
            height: 10,
          ),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
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
