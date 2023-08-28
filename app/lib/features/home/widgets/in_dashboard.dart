import 'package:acter/features/news/widgets/news_widget.dart';
import 'package:flutter/material.dart';

class InDashboard extends StatelessWidget {
  final Widget child;
  const InDashboard({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constrains) {
        if (constrains.maxWidth > 770) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Flexible(
                flex: 1,
                child: NewsWidget(),
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
