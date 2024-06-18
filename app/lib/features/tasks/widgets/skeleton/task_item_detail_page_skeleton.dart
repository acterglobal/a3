import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class TaskItemDetailPageSkeleton extends StatelessWidget {
  const TaskItemDetailPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(L10n.of(context).thisIsAMultilineDescription),
          ),
          ListTile(
            dense: true,
            leading: const Icon(Atlas.calendar_date_thin),
            title: Text(L10n.of(context).dueDate),
            subtitle: Text(L10n.of(context).dueDate),
          ),
          ListTile(
            dense: true,
            leading: const Icon(Atlas.business_man_thin),
            title: Text(L10n.of(context).assignment),
            subtitle: Text(L10n.of(context).assignment),
            trailing: Text(L10n.of(context).assigningSelf),
          ),
        ],
      ),
    );
  }
}
