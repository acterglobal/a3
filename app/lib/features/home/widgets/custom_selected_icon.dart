import 'package:acter/features/home/data/keys.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomSelectedIcon extends ConsumerWidget {
  final Widget icon;

  const CustomSelectedIcon({super.key, required this.icon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onDoubleTap: () {
        if (key == MainNavKeys.updates) {
          ref.read(boostGoToPageProvider.notifier).goToPage(0);
        }
      },
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
