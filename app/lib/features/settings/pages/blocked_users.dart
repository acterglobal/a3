import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter/features/settings/widgets/settings_menu.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddUserToBlock extends StatefulWidget {
  const AddUserToBlock({
    Key? key,
  }) : super(key: key);

  @override
  State<AddUserToBlock> createState() => _AddUserToBlockState();
}

class _AddUserToBlockState extends State<AddUserToBlock> {
  final TextEditingController userName = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Block user with username'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(5),
              child: TextFormField(
                controller: userName,
                validator: (value) => value != null &&
                        value.startsWith('@') &&
                        value.contains(':')
                    ? null
                    : 'Format must be @user:server.tld',
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, userName.text);
            }
          },
          child: const Text('Block'),
        ),
      ],
    );
  }
}

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
          actions: [
            IconButton(
              icon: Icon(
                Atlas.plus_circle_thin,
                color: Theme.of(context).colorScheme.neutral5,
              ),
              iconSize: 28,
              color: Theme.of(context).colorScheme.surface,
              onPressed: () async {
                final userToAdd = await showDialog<String?>(
                  context: context,
                  builder: (BuildContext context) => const AddUserToBlock(),
                );
                if (userToAdd != null) {
                  final account = ref
                      .read(accountProvider)
                      .requireValue; // is guaranteed because of the ignoredUsersProvider using it

                  await account.ignoreUser(userToAdd);
                  if (context.mounted) {
                    customMsgSnackbar(
                      context,
                      '$userToAdd added to block list. UI might take a bit too update',
                    );
                  }
                }
              },
            ),
          ],
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
