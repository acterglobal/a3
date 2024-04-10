import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class EventItemSkeleton extends StatelessWidget {
  const EventItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(child: _buildEventItemSkeletonUI(context));
  }

  Widget _buildEventItemSkeletonUI(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            height: 70,
            width: 70,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(L10n.of(context).eventTitleData),
                Text(L10n.of(context).eventDescriptionsData),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Text(L10n.of(context).rsvp),
        ],
      ),
    );
  }
}
