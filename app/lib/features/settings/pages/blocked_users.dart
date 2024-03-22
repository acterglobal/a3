import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class AddUserToBlock extends StatefulWidget {
  const AddUserToBlock({
    super.key,
  });

  @override
  State<AddUserToBlock> createState() => _AddUserToBlockState();
}

class _AddUserToBlockState extends State<AddUserToBlock> {
  final TextEditingController userName = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(L10n.of(context).blockUserWithUsername),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(5),
              child: TextFormField(
                controller: userName,
                validator: (value) => value?.startsWith('@') == true &&
                        value?.contains(':') == true
                    ? null
                    : L10n.of(context).formatMustBe,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        OutlinedButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(L10n.of(context).cancel),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, userName.text);
            }
          },
          child: Text(L10n.of(context).block),
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
      sidebar: const SettingsPage(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const AppBarTheme().backgroundColor,
          elevation: 0.0,
          title: Text(L10n.of(context).blockedUsers),
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
                  final account = ref.read(accountProvider);

                  await account.ignoreUser(userToAdd);
                  if (context.mounted) {
                    customMsgSnackbar(
                      context,
                      L10n.of(context).userAddedToBlockList(userToAdd),
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
                              child: Text(L10n.of(context).unblock),
                              onPressed: () async {
                                final account = ref.read(accountProvider);
                                await account.unignoreUser(user.toString());
                                if (context.mounted) {
                                  customMsgSnackbar(
                                    context,
                                    L10n.of(context).userRemovedFromList,
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
              : Center(
                  child: Text(L10n.of(context).hereYouCanSeeAllUsersYouBlocked),
                ),
          error: (error, stack) {
            return Center(
              child: Text('${L10n.of(context).failedToLoad}: $error'),
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
