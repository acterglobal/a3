import 'package:flutter/material.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:skeletonizer/skeletonizer.dart';

class EventListSkeleton extends StatefulWidget {
  const EventListSkeleton({super.key});

  @override
  State<EventListSkeleton> createState() => _EventListSkeletonState();
}

class _EventListSkeletonState extends State<EventListSkeleton> {
  @override
  Widget build(BuildContext context) {
    return Skeletonizer(child: _buildSkeletonUI());
  }

  Widget _buildSkeletonUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildEventItemSkeletonUI(),
        _buildEventItemSkeletonUI(),
        _buildEventItemSkeletonUI(),
      ],
    );
  }

  Widget _buildEventItemSkeletonUI() {
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
