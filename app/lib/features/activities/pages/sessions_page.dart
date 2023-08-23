import 'package:acter/features/activities/providers/session_providers.dart';
import 'package:acter/features/activities/widgets/session_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionsPage extends ConsumerWidget {
  const SessionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const AppBarTheme().backgroundColor,
        elevation: 0.0,
        title: const Text('Sessions'),
        centerTitle: true,
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            child: Text(
              'Unverified Sessions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Consumer(builder: unverifiedSessionsBuilder),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            child: Text(
              'All Sessions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Consumer(builder: allSessionsBuilder),
        ],
      ),
    );
  }

  Widget allSessionsBuilder(
    BuildContext context,
    WidgetRef ref,
    Widget? child,
  ) {
    final allSessions = ref.watch(allSessionsProvider);
    return allSessions.when(
      data: (sessions) => Expanded(
        child: ListView.builder(
          itemBuilder: (BuildContext context, int index) {
            return SessionCard(deviceRecord: sessions[index]);
          },
          itemCount: sessions.length,
        ),
      ),
      error: (error, stack) {
        return const Text("Couldn't load all sessions");
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget unverifiedSessionsBuilder(
    BuildContext context,
    WidgetRef ref,
    Widget? child,
  ) {
    final allSessions = ref.watch(allSessionsProvider);
    return allSessions.when(
      data: (data) {
        final sessions = data.where((sess) => !sess.isVerified()).toList();
        return Expanded(
          child: ListView.builder(
            itemBuilder: (BuildContext context, int index) {
              return SessionCard(deviceRecord: sessions[index]);
            },
            itemCount: sessions.length,
          ),
        );
      },
      error: (error, stack) {
        return const Text("Couldn't load unverified sessions");
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
