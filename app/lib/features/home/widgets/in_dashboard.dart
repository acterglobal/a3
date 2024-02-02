import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/news/widgets/news_widget.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InDashboard extends StatelessWidget {
  final Widget child;

  const InDashboard({super.key, required this.child});

  @override
  Widget build(BuildContext buildContext) {
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
                    const NewsWidget(),
                    Visibility(
                      child: IconButton(
                        onPressed: () =>
                            context.pushNamed(Routes.actionAddUpdate.name),
                        icon: Icon(
                          Atlas.plus_circle_thin,
                          color: Theme.of(context).colorScheme.neutral5,
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
