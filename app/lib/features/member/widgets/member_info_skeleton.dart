import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class MemberInfoSkeleton extends StatelessWidget {
  const MemberInfoSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Skeletonizer(
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      width: 2,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  child: ActerAvatar(
                    options: const AvatarOptions.DM(
                      AvatarInfo(uniqueId: '@memberId:acter.global'),
                      size: 50,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Skeletonizer(
              child: Center(
                child: Text('Joe Kasiznky'),
              ),
            ),
            const SizedBox(height: 20),
            const Skeletonizer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('@memberid:acter.global'),
                  SizedBox(width: 5),
                  Icon(Icons.copy_outlined),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Skeletonizer(
              child: Center(
                child: OutlinedButton.icon(
                  icon: const Icon(Atlas.chats_thin),
                  onPressed: () {},
                  label: const Text('Start DM'),
                ),
              ),
            ),
            const Skeletonizer(
              child: Center(
                child: Text('This is you'),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
