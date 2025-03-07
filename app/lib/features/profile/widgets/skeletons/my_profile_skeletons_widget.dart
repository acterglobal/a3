import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MyProfileSkeletonWidget extends StatelessWidget {
  const MyProfileSkeletonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(child: _buildMyProfileSkeletonUI(context));
  }

  Widget _buildMyProfileSkeletonUI(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: CircleAvatar(
              maxRadius: 50,
              backgroundColor: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          const Text('Name'),
          const Text('User Display name data'),
          const SizedBox(height: 20),
          const Text('Username'),
          const Text('User name data'),
        ],
      ),
    );
  }
}
