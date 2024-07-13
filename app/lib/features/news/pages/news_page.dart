import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/plus_icon_widget.dart';
import 'package:acter/features/news/widgets/news_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NewsPage extends ConsumerWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPostNews =
        ref.watch(hasSpaceWithPermissionProvider('CanPostNews')).valueOrNull ??
            false;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        actions: <Widget>[
          Visibility(
            visible: canPostNews,
            child: PlusIconWidget(
              onPressed: () => context.pushNamed(Routes.actionAddUpdate.name),
            ),
          ),
        ],
      ),
      body: const NewsWidget(),
    );
  }
}
