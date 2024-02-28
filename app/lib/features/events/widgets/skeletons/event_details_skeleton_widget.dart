import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class EventDetailsSkeleton extends StatefulWidget {
  const EventDetailsSkeleton({super.key});

  @override
  State<EventDetailsSkeleton> createState() => _EventListSkeletonState();
}

class _EventListSkeletonState extends State<EventDetailsSkeleton> {
  @override
  Widget build(BuildContext context) {
    return Skeletonizer(child: _buildSkeletonUI());
  }

  Widget _buildSkeletonUI() {
    return Column(
      children: [
        _buildEventHeaderSkeletonUI(),
        _buildEventBasicInfoSkeletonUI(),
        _buildEventRsvpButtonsSkeletonUI(),
        _buildEventAboutSkeletonUI(),
      ],
    );
  }

  Widget _buildEventHeaderSkeletonUI() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          const SizedBox(height: 100),
          Container(
            height: 200,
            width: MediaQuery.of(context).size.width,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildEventBasicInfoSkeletonUI() {
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

  Widget _buildEventRsvpButtonsSkeletonUI() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 80,
              width: 80,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Container(
              height: 80,
              width: 80,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Container(
              height: 80,
              width: 80,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventAboutSkeletonUI() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 150,
        width: MediaQuery.of(context).size.width,
        color: Colors.white,
      ),
    );
  }
}
