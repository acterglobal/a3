import 'package:acter/features/events/widgets/skeletons/event_item_skeleton_widget.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

class NewsSkeletonWidget extends StatelessWidget {
  const NewsSkeletonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(child: _buildNewsSkeletonUI(context));
  }

  Widget _buildNewsSkeletonUI(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      alignment: Alignment.center,
      child: Stack(
        children: [
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Spacer(),
              Text(
                'Lorem Ipsum is simply dummy text of the printing and typesetting industry.'
                'Lorem Ipsum is simply dummy text of the printing and typesetting industry.'
                'Lorem Ipsum is simply dummy text of the printing and typesetting industry.',
              ),
              Spacer(),
              EventItemSkeleton(),
            ],
          ),
          Positioned.fill(
            bottom: 100,
            right: 26,
            child: Align(
              alignment: Alignment.bottomRight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(PhosphorIcons.heart()),
                  const SizedBox(height: 20),
                  Icon(PhosphorIcons.heart()),
                  const SizedBox(height: 20),
                  Icon(PhosphorIcons.heart()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
