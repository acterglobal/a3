import 'package:acter/features/home/providers/client_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final backupManagerProvider = FutureProvider(
  (ref) => ref.watch(
    alwaysClientProvider.selectAsync((client) => client.backupManager()),
  ),
);
