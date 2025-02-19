import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::settings::blocked_users');

class AddUserToBlock extends StatefulWidget {
  const AddUserToBlock({super.key});

  @override
  State<AddUserToBlock> createState() => _AddUserToBlockState();
}

class _AddUserToBlockState extends State<AddUserToBlock> {
  final TextEditingController userName = TextEditingController();
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(debugLabel: 'blocked user form');

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return AlertDialog(
      title: Text(lang.blockUserWithUsername),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(5),
              child: TextFormField(
                controller: userName,
                // required field, custom format
                validator: (val) =>
                    val == null || !val.startsWith('@') || !val.contains(':')
                        ? lang.formatMustBe
                        : null,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        OutlinedButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(lang.cancel),
        ),
        ActerPrimaryActionButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, userName.text);
          },
          child: Text(lang.block),
        ),
      ],
    );
  }
}

class BlockedUsersPage extends ConsumerWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final usersLoader = ref.watch(ignoredUsersProvider);
    return WithSidebar(
      sidebar: const SettingsPage(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !context.isLargeScreen,
          title: Text(lang.blockedUsers),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Atlas.plus_circle_thin),
              iconSize: 28,
              color: Theme.of(context).colorScheme.surface,
              onPressed: () => onAdd(context, ref),
            ),
          ],
        ),
        body: usersLoader.when(
          data: (users) {
            if (users.isEmpty) {
              return Center(
                child: Text(lang.hereYouCanSeeAllUsersYouBlocked),
              );
            }
            return CustomScrollView(
              slivers: [
                SliverList.builder(
                  itemBuilder: (BuildContext context, int index) {
                    final userId = users[index].toString();
                    return Card(
                      margin: const EdgeInsets.all(5),
                      child: ListTile(
                        title: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(userId),
                        ),
                        trailing: OutlinedButton(
                          child: Text(lang.unblock),
                          onPressed: () => onDelete(context, ref, userId),
                        ),
                      ),
                    );
                  },
                  itemCount: users.length,
                ),
              ],
            );
          },
          error: (e, s) {
            _log.severe('Failed to load the ignored users', e, s);
            return Center(
              child: Text(lang.loadingFailed(e)),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  Future<void> onAdd(BuildContext context, WidgetRef ref) async {
    final lang = L10n.of(context);
    final userToAdd = await showDialog<String?>(
      context: context,
      builder: (context) => const AddUserToBlock(),
    );
    if (userToAdd == null) return;
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.show(status: lang.blockingUserProgress);
    try {
      final account = await ref.read(accountProvider.future);
      await account.ignoreUser(userToAdd);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(lang.userAddedToBlockList(userToAdd));
    } catch (e, s) {
      _log.severe('Failed to block user', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.blockingUserFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> onDelete(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final lang = L10n.of(context);
    EasyLoading.show(status: lang.unblockingUser);
    try {
      final account = await ref.read(accountProvider.future);
      await account.unignoreUser(userId);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast(lang.userRemovedFromList);
    } catch (e, s) {
      _log.severe('Failed to unblock user', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.unblockingUserFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
