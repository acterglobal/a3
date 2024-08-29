import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class EventDetailsSkeleton extends StatelessWidget {
  const EventDetailsSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Skeletonizer(child: _buildEventHeaderSkeletonUI(context)),
          Skeletonizer(child: _buildEventBasicInfoSkeletonUI(context)),
          Skeletonizer(child: _buildEventRsvpButtonsSkeletonUI(context)),
          Skeletonizer(child: _buildEventAboutSkeletonUI(context)),
        ],
      ),
    );
  }

  Widget _buildEventHeaderSkeletonUI(BuildContext context) {
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

  Widget _buildEventBasicInfoSkeletonUI(BuildContext context) {
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(L10n.of(context).eventTitleData),
              Text(L10n.of(context).eventDescriptionsData),
            ],
          ),
          const SizedBox(width: 20),
          Text(L10n.of(context).rsvp),
        ],
      ),
    );
  }

  Widget _buildEventRsvpButtonsSkeletonUI(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            height: 80,
            width: 80,
            color: Colors.white,
          ),
          const SizedBox(width: 20),
          Container(
            height: 80,
            width: 80,
            color: Colors.white,
          ),
          const SizedBox(width: 20),
          Container(
            height: 80,
            width: 80,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildEventAboutSkeletonUI(BuildContext context) {
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
