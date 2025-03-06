import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:skeletonizer/skeletonizer.dart';

class EventItemSkeleton extends StatelessWidget {
  const EventItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(child: _buildEventItemSkeletonUI(context));
  }

  Widget _buildEventItemSkeletonUI(BuildContext context) {
    final lang = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(height: 70, width: 70, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lang.eventTitleData),
                Text(lang.eventDescriptionsData),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Text(lang.rsvp),
        ],
      ),
    );
  }
}
