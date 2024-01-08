import 'dart:core';
import 'package:acter/common/widgets/webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/themes/app_theme.dart';

class SpaceWidgets extends ConsumerWidget {
  final String spaceIdOrAlias;
  const SpaceWidgets({super.key, required this.spaceIdOrAlias});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // get platform of context.
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
      child: Padding(padding: EdgeInsets.all(20), child: WebView()),
    );
  }
}
