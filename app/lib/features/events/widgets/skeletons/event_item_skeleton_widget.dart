import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class EventItemSkeleton extends StatelessWidget {
  const EventItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(child: _buildEventItemSkeletonUI());
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Event title data'),
                Text('Event Descriptions data'),
              ],
            ),
          ),
          const SizedBox(width: 20),
          const Text('RSVP'),
        ],
      ),
    );
  }
}
