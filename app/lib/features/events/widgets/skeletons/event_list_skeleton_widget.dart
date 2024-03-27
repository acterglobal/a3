import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

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
      children: [
        _buildEventItemSkeletonUI(),
        _buildEventItemSkeletonUI(),
        _buildEventItemSkeletonUI(),
      ],
    );
  }

  Widget _buildEventItemSkeletonUI() {
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
