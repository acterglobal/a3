import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:acter/features/super_invites/providers/super_invites_providers.dart';
import 'package:acter/features/super_invites/widgets/redeem_token.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::super_invites::list');

class SuperInvitesPage extends ConsumerWidget {
  static Key createNewToken = const Key('super-invites-create');

  const SuperInvitesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tokensLoader = ref.watch(superInvitesTokensProvider);
    return WithSidebar(
      sidebar: const SettingsPage(),
      child: Scaffold(
        appBar: AppBar(
          elevation: 0.0,
          title: Text(lang.superInvites),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Atlas.arrows_rotating_right_thin),
              iconSize: 28,
              color: colorScheme.surface,
              onPressed: () {
                ref.invalidate(superInvitesTokensProvider);
              },
            ),

            IconButton(
              key: createNewToken,
              icon: const Icon(Atlas.plus_circle_thin),
              iconSize: 28,
              color: colorScheme.surface,
              onPressed: () {
                context.pushNamed(Routes.actionCreateSuperInvite.name);
              },
            ),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: RedeemToken()),
            tokensLoader.when(
              data: (tokens) {
                if (tokens.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Text(lang.youHaveNotCreatedInviteCodes),
                    ),
                  );
                }
                return SliverList.builder(
                  itemBuilder: (context, index) {
                    final token = tokens[index];
                    final acceptedCount = lang.usedTimes(token.acceptedCount());
                    final tokenStr = token.token();
                    final firstRoom =
                        asDartStringList(token.rooms()).firstOrNull;
                    return Card(
                      key: Key('edit-token-$tokenStr'),
                      margin: const EdgeInsets.all(5),
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: ListTile(
                          title: Text(
                            tokenStr,
                            style: textTheme.headlineSmall,
                          ),
                          subtitle: Text(
                            acceptedCount,
                            style: textTheme.bodySmall,
                          ),
                          onTap: () {
                            context.pushNamed(
                              Routes.createSuperInvite.name,
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
                                  child: Text(lang.share),
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                  itemCount: tokens.length,
                );
              },
              error: (e, s) {
                _log.severe('Failed to load the super invite tokens', e, s);
                return SliverToBoxAdapter(
                  child: Center(
                    child: Text(lang.failedToLoadInviteCodes(e)),
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
