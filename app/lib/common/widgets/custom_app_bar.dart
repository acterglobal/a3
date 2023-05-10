import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomAppBar extends AppBar {
  CustomAppBar({
    required Key key,
    required Widget title,
    required BuildContext context,
  }) : super(
          key: key,
          title: title,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Atlas.arrow_left),
          ),
          centerTitle: true,
          titleTextStyle: Theme.of(context).textTheme.titleMedium,
        );
}
