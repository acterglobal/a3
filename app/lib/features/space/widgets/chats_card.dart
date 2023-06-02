import 'dart:core';
import 'package:acter/common/providers/common_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class ChatsCard extends ConsumerWidget {
  final String spaceId;

  const ChatsCard({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(relatedChatsProvider(spaceId));
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chats',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            chats.when(
              error: (error, stack) => Text('Loading chats failed: $error'),
              loading: () => const Text('Loading'),
              data: (chats) {
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final roomId = chats[index].getRoomId().toString();
                    final provider = chatProfileDataProvider(chats[index]);
                    final profile = ref.watch(provider);
                    return profile.when(
                      data: (profile) => ListTile(
                        onTap: () => context.go('/chat/$roomId'),
                        title: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                profile.hasAvatar()
                                    ? CircleAvatar(
                                        foregroundImage:
                                            profile.getAvatarImage(),
                                        radius: 18,
                                      )
                                    : SvgPicture.asset(
                                        'assets/icon/acter.svg',
                                        height: 32,
                                        width: 32,
                                      ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    profile.displayName ?? roomId,
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 16,
                              ),
                              child: const Divider(indent: 0),
                            ),
                          ],
                        ),
                      ),
                      error: (error, stack) => ListTile(
                        title: Text('Error loading: $roomId'),
                        subtitle: Text('$error'),
                      ),
                      loading: () => ListTile(
                        title: Text(roomId),
                        subtitle: const Text('loading'),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
