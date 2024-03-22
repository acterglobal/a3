import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:acter/features/settings/providers/session_providers.dart';
import 'package:acter/features/settings/widgets/session_card.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionsPage extends ConsumerWidget {
  const SessionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSessions = ref.watch(unknownSessionsProvider);
    return WithSidebar(
      sidebar: const SettingsPage(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const AppBarTheme().backgroundColor,
          elevation: 0.0,
          title: Text(L10n.of(context).sessions),
          centerTitle: true,
        ),
        body: allSessions.when(
          data: (sessions) => buildSessions(context, sessions),
          error: (error, stack) {
            return Center(
              child: Text(L10n.of(context).couldNotLoadAllSessions),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  Widget buildSessions(
    BuildContext context,
    List<DeviceRecord> sessions,
  ) {
    final unverifiedSessions = sessions.where((s) => !s.isVerified()).toList();

    if (unverifiedSessions.isNotEmpty) {
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
                Text(
                  L10n.of(context).unverifiedSessions,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
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
              L10n.of(context).unverifiedSessionsDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        SliverList.builder(
          itemBuilder: (BuildContext context, int index) {
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
                '${L10n.of(context).verified} ${L10n.of(context).sessions}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          SliverList.builder(
            itemBuilder: (BuildContext context, int index) {
              return SessionCard(deviceRecord: verifiedSessions[index]);
            },
            itemCount: verifiedSessions.length,
          ),
        ]);
      }
      return CustomScrollView(slivers: slivers);
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            child: Text(
              L10n.of(context).verifiedSessionsDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        SliverList.builder(
          itemBuilder: (BuildContext context, int index) {
            return SessionCard(deviceRecord: sessions[index]);
          },
          itemCount: sessions.length,
        ),
      ],
    );
  }
}
