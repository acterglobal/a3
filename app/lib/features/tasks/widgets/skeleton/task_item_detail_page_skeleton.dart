import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:skeletonizer/skeletonizer.dart';

class TaskItemDetailPageSkeleton extends StatelessWidget {
  const TaskItemDetailPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return Skeletonizer(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Text(lang.thisIsAMultilineDescription),
          ),
          ListTile(
            dense: true,
            leading: const Icon(Atlas.calendar_date_thin),
            title: Text(lang.dueDate),
            subtitle: Text(lang.dueDate),
          ),
          ListTile(
            dense: true,
            leading: const Icon(Atlas.business_man_thin),
            title: Text(lang.assignment),
            subtitle: Text(lang.assignment),
            trailing: Text(lang.assigningSelf),
          ),
        ],
      ),
    );
  }
}
