import 'dart:core';

import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';

class MySpacesSection extends ConsumerWidget {
  final int? limit;
  const MySpacesSection({super.key, this.limit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaces = ref.watch(spacesProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              context.pushNamed(
                Routes.spaces.name,
              );
            },
            child: Text(
              'My Spaces',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 10),
          spaces.when(
            data: (data) {
              if (data.isEmpty) {
                return const _NoSpacesWidget();
              }
              List<Space> listing = data;
              final total = data.length;
              int sublistLen = data.length;
              if (limit != null) {
                sublistLen = limit!;
                listing = data.sublist(0, limit);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: listing.length,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final roomId = listing[index].getRoomId().toString();
                      final spaceProfile =
                          ref.watch(spaceProfileDataProvider(data[index]));
                      return spaceProfile.when(
                        data: (profile) => Card(
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color:
                                  Theme.of(context).colorScheme.inversePrimary,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          color: Theme.of(context).colorScheme.surface,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(15),
                            onTap: () => context.go('/$roomId'),
                            title: Text(
                              profile.displayName ?? roomId,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            leading: ActerAvatar(
                              mode: DisplayMode.Space,
                              displayName: profile.displayName,
                              uniqueId: roomId,
                              avatar: profile.getAvatarImage(),
                              size: 48,
                            ),
                            trailing: const Icon(Icons.more_vert),
                          ),
                        ),
                        error: (error, stackTrace) =>
                            Text('Failed to load space due to $error'),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                  sublistLen != total
                      ? Padding(
                          padding: const EdgeInsets.only(left: 30, top: 8),
                          child: OutlinedButton(
                            onPressed: () {
                              context.pushNamed(
                                Routes.spaces.name,
                              );
                            },
                            child: Text('see all my $total spaces'),
                          ),
                        )
                      : const Text(''),
                ],
              );
            },
            error: (error, stackTrace) =>
                Text('Failed to load spaces due to $error'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}

class _NoSpacesWidget extends ConsumerWidget {
  const _NoSpacesWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 15),
        Text(
          'You are currently not connected to any spaces',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 30),
        RichText(
          text: TextSpan(
            children: <TextSpan>[
              TextSpan(
                text: 'Create\t',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const TextSpan(text: 'or\t'),
              TextSpan(
                text: 'join\t',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextSpan(
                text: 'a space, to start organising and collaborating',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          softWrap: true,
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.15,
        ),
        Center(
          child: ElevatedButton(
            onPressed: () => context.goNamed(Routes.createSpace.name),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Create New Space',
                ),
                SizedBox(width: 10),
                Icon(Icons.chevron_right_outlined)
              ],
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.neutral6,
              foregroundColor: Theme.of(context).colorScheme.neutral,
              textStyle: Theme.of(context).textTheme.bodyLarge,
              fixedSize: const Size(311, 61),
              shape: RoundedRectangleBorder(
                side: BorderSide.none,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        const SizedBox(height: 36),
        Center(
          child: ElevatedButton(
            onPressed: () {},
            child: const Text('Join Existing Space'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Theme.of(context).colorScheme.neutral6,
              textStyle: Theme.of(context).textTheme.bodyLarge,
              fixedSize: const Size(311, 61),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: Theme.of(context).colorScheme.neutral6,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
