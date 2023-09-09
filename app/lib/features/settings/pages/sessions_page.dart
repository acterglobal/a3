import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/activities/providers/session_providers.dart';
import 'package:acter/features/activities/widgets/session_card.dart';
import 'package:acter/features/settings/widgets/settings_menu.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionsPage extends ConsumerWidget {
  const SessionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSessions = ref.watch(allSessionsProvider);
    return WithSidebar(
      sidebar: const SettingsMenu(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const AppBarTheme().backgroundColor,
          elevation: 0.0,
          title: const Text('Sessions'),
          centerTitle: true,
        ),
        body: allSessions.when(
          data: (sessions) => buildSessions(context, sessions),
          error: (error, stack) {
            return const Center(
              child: Text("Couldn't load all sessions"),
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
                  'Unverified Sessions',
                  style: Theme.of(context).textTheme.headlineSmall,
                )
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
              "You have devices logged in your account that aren't verified. This can be a security risk. Please ensure this is okay.",
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
                'Verified Sessions',
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
              'All your devices are verified. Your account is secure',
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
