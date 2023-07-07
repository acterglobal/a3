import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/news/widgets/news_widget.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NewsPage extends ConsumerWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDesktop =
        desktopPlatforms.contains(Theme.of(context).platform);

    final canPostNews =
        ref.watch(hasSpaceWithPermissionProvider('CanPostNews')).valueOrNull ??
            false;

    print("can post news $canPostNews");
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        actions: <Widget>[
          Visibility(
            visible: canPostNews,
            child: IconButton(
              /// [GoRouter] use context.push() for preserving states
              /// of previous route and context.go() for vice versa.
              onPressed: () => context.pushNamed(Routes.actionAddUpdate.name),
              icon: Icon(
                Atlas.plus_circle_thin,
                color: Theme.of(context).colorScheme.neutral5,
                size: 36,
              ),
            ),
          ),
        ],
      ),
      body: const NewsWidget(),
    );
  }
}
