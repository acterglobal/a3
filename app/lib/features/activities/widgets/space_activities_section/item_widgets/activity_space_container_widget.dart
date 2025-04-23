import 'package:acter/features/comments/widgets/time_ago_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//Main container for all activity item widgets
class ActivitySpaceProfileChangeContainerWidget extends ConsumerWidget {
  final Widget? leadingWidget;
  final String titleText;
  final Widget? subtitleWidget;
  final int originServerTs;

  const ActivitySpaceProfileChangeContainerWidget({
    super.key,
    this.leadingWidget,
    required this.titleText,
    this.subtitleWidget,
    required this.originServerTs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              buildUserInfoUI(context, ref),
              TimeAgoWidget(originServerTs: originServerTs),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildUserInfoUI(BuildContext context, WidgetRef ref) {
    return ListTile(
      horizontalTitleGap: 10,
      contentPadding: EdgeInsets.zero,
      leading: leadingWidget ?? const SizedBox.shrink(),
      title: Text(titleText),
      subtitle: subtitleWidget ?? const SizedBox.shrink(),
    );
  }
}
