import 'package:flutter/material.dart';

class CustomSelectedIcon extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;

  const CustomSelectedIcon({super.key, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 30,
        width: 54,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(child: icon),
      ),
    );
  }
}
