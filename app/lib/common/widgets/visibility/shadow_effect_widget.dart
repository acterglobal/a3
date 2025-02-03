import 'package:flutter/material.dart';

class ShadowEffectWidget extends StatelessWidget {

  final Widget child;

  const ShadowEffectWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.3), // Shadow color
            spreadRadius: 1, // How much the shadow spreads
            blurRadius: 15, // How much the shadow blurs
            offset: const Offset(0, 4), // Adjust the shadow to be slightly below the icon
          ),
        ],
      ),
      child: child,
    );
  }
}
