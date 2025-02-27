import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:skeletonizer/skeletonizer.dart';

class GeneralListSkeletonWidget extends StatelessWidget {
  const GeneralListSkeletonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(child: _buildSkeletonUI(context));
  }

  Widget _buildSkeletonUI(BuildContext context) {
    return Column(
      children: List.generate(5, (_) => _buildListItemSkeletonUI(context)),
    );
  }

  Widget _buildListItemSkeletonUI(BuildContext context) {
    final lang = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(height: 50, width: 50, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lang.title + lang.title),
                Text(lang.description + lang.description),
              ],
            ),
          ),
          const SizedBox(width: 20),
          const Icon(Atlas.crown_winner_thin),
          const SizedBox(width: 10),
          const Icon(Atlas.dots_vertical),
        ],
      ),
    );
  }
}
