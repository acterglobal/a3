import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:acter/features/news/pages/news_list_page.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class InDashboard extends ConsumerWidget {
  final Widget child;

  const InDashboard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canPostNews = ref
            .watch(
              hasSpaceWithPermissionProvider('CanPostNews'),
            )
            .valueOrNull ==
        true;
    return LayoutBuilder(
      builder: (context, constrains) {
        if (constrains.maxWidth > 770) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                flex: 1,
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    const NewsListPage(gridMode: false),
                    Visibility(
                      visible: canPostNews,
                      child: IconButton(
                        key: NewsUpdateKeys.addNewsUpdate,
                        onPressed: () =>
                            context.pushNamed(Routes.actionAddUpdate.name),
                        icon: const Icon(
                          Atlas.plus_circle_thin,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                flex: 2,
                child: child,
              ),
            ],
          );
        }
        return child;
      },
    );
  }
}
