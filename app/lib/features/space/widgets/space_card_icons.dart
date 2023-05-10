import 'package:flutter/material.dart';

class SpaceCardIcons extends StatelessWidget {
  final String? title;
  final IconData? icon;

  const SpaceCardIcons({
    super.key,
    this.title,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 60,
          width: 60,
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
              color: const Color(0xff4A4458),
              borderRadius: BorderRadius.circular(20)),
          child: Icon(icon),
        ),
        Text(
          title!,
          style: const TextStyle(fontSize: 15),
        )
      ],
    );
  }
}