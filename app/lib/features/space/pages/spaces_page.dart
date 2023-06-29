import 'package:acter/common/providers/space_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:go_router/go_router.dart';

import 'dart:math';

class SpacesPage extends ConsumerStatefulWidget {
  const SpacesPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SpacesPageState();
}

class _SpacesPageState extends ConsumerState<SpacesPage> {
  @override
  Widget build(BuildContext context) {
    final spaces = ref.watch(spaceItemsProvider);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: <Color>[
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.neutral,
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              backgroundColor: Colors.transparent,
              actions: <Widget>[
                PopupMenuButton(
                  icon: Icon(
                    Atlas.plus_circle,
                    color: Theme.of(context).colorScheme.neutral5,
                  ),
                  iconSize: 28,
                  color: Theme.of(context).colorScheme.surface,
                  itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                    PopupMenuItem(
                      onTap: () => context.pushNamed(Routes.createSpace.name),
                      child: Row(
                        children: const <Widget>[
                          Text('Create Space'),
                          Spacer(),
                          Icon(Atlas.connection),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      onTap: () => customMsgSnackbar(
                        context,
                        'Join space feature isn\'t implemented yet',
                      ),
                      child: Row(
                        children: const <Widget>[
                          Text('Join Space'),
                          Spacer(),
                          Icon(Atlas.calendar_dots),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              title: const Text('Spaces'),
            ),
            spaces.when(
              data: (spaces) {
                final widthCount =
                    (MediaQuery.of(context).size.width ~/ 600).toInt();
                const int minCount = 2;
                // we have more than just the spaces screen, put them into a grid.
                return SliverGrid.builder(
                  itemCount: spaces.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: max(1, min(widthCount, minCount)),
                    childAspectRatio: 6,
                  ),
                  itemBuilder: (context, index) {
                    final space = spaces[index];
                    final profile = space.spaceProfileData;
                    final roomId = space.roomId;
                    return Card(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.inversePrimary,
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
                    );
                  },
                );
              },
              error: (error, stack) => SliverToBoxAdapter(
                child: Text('Loading failed: $error'),
              ),
              loading: () => const SliverToBoxAdapter(
                child: Text('Loading'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
