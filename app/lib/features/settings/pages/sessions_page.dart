import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:acter/features/settings/providers/session_providers.dart';
import 'package:acter/features/settings/widgets/session_card.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::settings::sessions');

class SessionsPage extends ConsumerWidget {
  const SessionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final sessionsLoader = ref.watch(unknownSessionsProvider);
    return WithSidebar(
      sidebar: const SettingsPage(),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !context.isLargeScreen,
          title: Text(lang.sessions),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Atlas.arrows_rotating_right_thin),
              iconSize: 28,
              color: Theme.of(context).colorScheme.surface,
              onPressed: () {
                ref.invalidate(allSessionsProvider);
              },
            ),
          ],
        ),
        body: sessionsLoader.when(
          data: (sessions) => buildSessions(context, sessions),
          error: (e, s) {
            _log.severe('Failed to load unknown sessions', e, s);
            return Center(child: Text(lang.couldNotLoadAllSessions));
          },
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Widget buildSessions(BuildContext context, List<DeviceRecord> sessions) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    final unverifiedSessions = sessions.where((s) => !s.isVerified()).toList();

    if (unverifiedSessions.isEmpty) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
              child: Text(
                lang.verifiedSessionsDescription,
                style: textTheme.bodyMedium,
              ),
            ),
          ),
          SliverList.builder(
            itemBuilder: (context, index) {
              return SessionCard(deviceRecord: sessions[index]);
            },
            itemCount: sessions.length,
          ),
        ],
      );
    }

    final slivers = [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(
                  Atlas.shield_exclamation_thin,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              Text(lang.unverifiedSessions, style: textTheme.headlineSmall),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 20,
            vertical: 15,
          ),
          child: Text(
            lang.unverifiedSessionsDescription,
            style: textTheme.bodyMedium,
          ),
        ),
      ),
      SliverList.builder(
        itemBuilder: (context, index) {
          return SessionCard(deviceRecord: unverifiedSessions[index]);
        },
        itemCount: unverifiedSessions.length,
      ),
    ];

    final verifiedSessions = sessions.where((s) => s.isVerified()).toList();

    if (verifiedSessions.isNotEmpty) {
      slivers.addAll([
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            child: Text(
              '${lang.verified} ${lang.sessions}',
              style: textTheme.headlineSmall,
            ),
          ),
        ),
        SliverList.builder(
          itemBuilder: (context, index) {
            return SessionCard(deviceRecord: verifiedSessions[index]);
          },
          itemCount: verifiedSessions.length,
        ),
      ]);
    }
    return CustomScrollView(slivers: slivers);
  }
}
