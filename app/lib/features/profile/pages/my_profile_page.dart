import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/snackbars/not_implemented.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MyProfile extends ConsumerWidget {
  const MyProfile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountProfileProvider);
    return account.when(
      data: (account) => Scaffold(
        appBar: AppBar(
          title: const Text('My profile'),
          actions: [
            IconButton(
              icon: const Icon(Atlas.pencil_edit_thin),
              onPressed: () {
                showNotYetImplementedMsg(
                  context,
                  'Profile Edit page not yet implemented',
                );
              },
            ),
            IconButton(
              icon: const Icon(Atlas.construction_tools_thin),
              onPressed: () {
                context.go('/settings');
              },
            )
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 15, 20, 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    width: double.infinity,
                    height: 230,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: const SizedBox(),
                    ),
                  ),
                  Positioned(
                    left: 50,
                    top: 40,
                    child: Container(
                      width: MediaQuery.of(context).size.width - 100,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            margin: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(60),
                              border: Border.all(width: 5),
                            ),
                            child: ActerAvatar(
                              mode: DisplayMode.User,
                              uniqueId: account.account.userId().toString(),
                              avatar: account.profile.getAvatarImage(),
                              displayName: account.profile.displayName,
                              size: 60,
                            ),
                          ),
                          Text(account.profile.displayName ?? ''),
                          Text(account.account.userId().toString()),
                        ],
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 25),
              DefaultTabController(
                length: 3,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const TabBar(
                      tabs: [
                        Tab(
                          child: Text('News'),
                        ),
                        Tab(
                          child: Text('Feed'),
                        ),
                        Tab(
                          child: Text('More details'),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height - 100,
                      child: const TabBarView(
                        physics: NeverScrollableScrollPhysics(),
                        children: [
                          Text(''),
                          Text(''),
                          Text(''),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
      error: (e, trace) => Text('error: $e'),
      loading: () => const Text('loading'),
    );
  }
}
