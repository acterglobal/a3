import 'package:acter/features/cross_signing/cross_signing.dart';
import 'package:acter/features/home/providers/notifiers/client_notifier.dart';
import 'package:acter/features/home/providers/notifiers/sync_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart' show Client;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final clientProvider = StateNotifierProvider<ClientNotifier, Client?>((ref) {
  return ClientNotifier(ref);
});

final syncStateProvider = StateNotifierProvider<SyncNotifier, bool>((ref) {
  final client = ref.watch(clientProvider);
  final crossSigning = CrossSigning(client: client!);
  return SyncNotifier(client);
});
