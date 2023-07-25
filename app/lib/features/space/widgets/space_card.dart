import 'package:acter/features/space/widgets/space_card_icons.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

import 'package:acter/common/utils/constants.dart';

class SpaceCard extends StatelessWidget {
  final String? displayImage;
  final String? title;
  final String? subtitle;
  final String? username;
  final String? displayName;
  final String? roomId;

  const SpaceCard({
    super.key,
    this.displayImage,
    this.title,
    this.subtitle,
    this.username,
    this.displayName,
    this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDesktop =
        desktopPlatforms.contains(Theme.of(context).platform);

    return !isDesktop
        ? Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            width: 300,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ActerAvatar(
                    mode: DisplayMode.Space,
                    uniqueId: roomId!,
                    displayName: username,
                    size: 50,
                  ),
                  Text(
                    title!,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    subtitle!,
                    style: const TextStyle(color: Color(0xff79747E)),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SpaceCardIcons(
                        icon: Atlas.ticket_plus,
                        title: 'Invite',
                      ),
                      SpaceCardIcons(
                        icon: Atlas.link_chain,
                        title: 'Copy link',
                      ),
                      SpaceCardIcons(
                        icon: Atlas.bell_dots,
                        title: 'Notifications',
                      )
                    ],
                  ),
                  const Divider(
                    thickness: 0.5,
                    indent: 1,
                    endIndent: 1,
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          child: const Icon(Atlas.padlock),
                        ),
                        const Text('Encryption Settings')
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          child: const Icon(
                            Atlas.block_shield,
                            color: Colors.red,
                          ),
                        ),
                        const Text(
                          'Leave Space',
                          style: TextStyle(color: Colors.red),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        : Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            width: 310,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      ActerAvatar(
                        mode: DisplayMode.Space,
                        uniqueId: '',
                        size: 50,
                      ),
                      const SizedBox(
                        width: 15,
                      ),
                      Column(
                        children: [
                          Text(
                            title!,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            subtitle!,
                            style: const TextStyle(color: Color(0xff79747E)),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SpaceCardIcons(
                        icon: Atlas.ticket_plus,
                        title: 'Invite',
                      ),
                      SpaceCardIcons(
                        icon: Atlas.link_chain,
                        title: 'Copy link',
                      ),
                      SpaceCardIcons(
                        icon: Atlas.bell_dots,
                        title: 'Notifications',
                      )
                    ],
                  ),
                  const Divider(
                    thickness: 0.5,
                    indent: 1,
                    endIndent: 1,
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          child: const Icon(Atlas.padlock),
                        ),
                        const Text('Encryption Settings')
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 10),
                          child: const Icon(
                            Atlas.block_shield,
                            color: Colors.red,
                          ),
                        ),
                        const Text(
                          'Leave Space',
                          style: TextStyle(color: Colors.red),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
  }
}
