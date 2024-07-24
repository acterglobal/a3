import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:acter/features/super_invites/providers/super_invites_providers.dart';
import 'package:acter/features/super_invites/widgets/redeem_token.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SuperInvitesPage extends ConsumerWidget {
  static Key createNewToken = const Key('super-invites-create');

  const SuperInvitesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = ref.watch(superInvitesTokensProvider);
    return WithSidebar(
      sidebar: const SettingsPage(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const AppBarTheme().backgroundColor,
          elevation: 0.0,
          title: Text(L10n.of(context).superInvites),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Atlas.arrows_rotating_right_thin),
              iconSize: 28,
              color: Theme.of(context).colorScheme.surface,
              onPressed: () async {
                ref.invalidate(superInvitesTokensProvider);
              },
            ),
            IconButton(
              key: createNewToken,
              icon: const Icon(Atlas.plus_circle_thin),
              iconSize: 28,
              color: Theme.of(context).colorScheme.surface,
              onPressed: () async {
                context.pushNamed(Routes.actionCreateSuperInvite.name);
              },
            ),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: RedeemToken()),
            tokens.when(
              data: (tokens) => tokens.isNotEmpty
                  ? SliverList.builder(
                      itemBuilder: (BuildContext context, int index) {
                        final token = tokens[index];
                        final tokenStr = token.token().toString();
                        final firstRoom = token
                            .rooms()
                            .map((t) => t.toDartString())
                            .firstOrNull;
                        return Card(
                          key: Key('edit-token-$tokenStr'),
                          margin: const EdgeInsets.all(5),
                          child: ListTile(
                            title: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Text(tokenStr),
                            ),
                            subtitle: Text(
                              L10n.of(context).usedTimes(token.acceptedCount()),
                            ),
                            onTap: () {
                              context.pushNamed(
                                Routes.actionCreateSuperInvite.name,
                                extra: token,
                              );
                            },
                            trailing: firstRoom != null
                                ? OutlinedButton(
                                    onPressed: () => context.pushNamed(
                                      Routes.shareInviteCode.name,
                                      queryParameters: {
                                        'inviteCode': tokenStr,
                                        'roomId': firstRoom,
                                      },
                                    ),
                                    child: Text(L10n.of(context).share),
                                  )
                                : null,
                          ),
                        );
                      },
                      itemCount: tokens.length,
                    )
                  : SliverToBoxAdapter(
                      child: Center(
                        child: Text(
                          L10n.of(context).youHaveNotCreatedInviteCodes,
                        ),
                      ),
                    ),
              error: (error, stack) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      L10n.of(context).failedToLoadInviteCodes(error),
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
