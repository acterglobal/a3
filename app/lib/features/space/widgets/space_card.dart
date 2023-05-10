import 'package:acter/features/space/widgets/space_card_icons.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

import 'package:acter/common/widgets/square_avatar.dart';


class SpaceCard extends StatelessWidget {
  const SpaceCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(10)),
      width: 300,
      child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SquareAvatar(
                height: 76,
                width: 77,
                displayImage: 'assets/icon/logo.png',
              ),
              Text(
                'OceanKAN Global',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Text(
                '#oceankan:acter.global',
                style: TextStyle(color: Color(0xff79747E)),
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
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
                        child: const Icon(Atlas.padlock)),
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
        )
    );
  }
}