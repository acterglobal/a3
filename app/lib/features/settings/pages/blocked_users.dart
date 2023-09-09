import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter/features/settings/widgets/settings_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BlockedUsersPage extends ConsumerWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(ignoredUsersProvider);
    return WithSidebar(
      sidebar: const SettingsMenu(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const AppBarTheme().backgroundColor,
          elevation: 0.0,
          title: const Text('Blocked Users'),
          centerTitle: true,
        ),
        body: users.when(
          data: (users) => users.isNotEmpty
              ? CustomScrollView(
                  slivers: [
                    SliverList.builder(
                      itemBuilder: (BuildContext context, int index) {
                        final user = users[index];
                        return Card(
                          margin: const EdgeInsets.all(5),
                          child: ListTile(
                            title: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(user.toString()),
                            ),
                            trailing: OutlinedButton(
                              child: const Text('Unblock'),
                              onPressed: () async {
                                final account = ref
                                    .read(accountProvider)
                                    .requireValue; // is guaranteed because of the ignoredUsersProvider using it
                                await account.unignoreUser(user.toString());
                                if (context.mounted) {
                                  customMsgSnackbar(
                                    context,
                                    'User removed from list. UI might take a bit too update',
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      },
                      itemCount: users.length,
                    ),
                  ],
                )
              : const Center(
                  child: Text("Here you can see all users you've blocked."),
                ),
          error: (error, stack) {
            return Center(
              child: Text('Failed to load: $error'),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}
