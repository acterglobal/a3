import 'package:acter/features/home/providers/client_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationConfiguration {
  final bool encrypted;
  final bool oneToOne;
  const NotificationConfiguration(this.encrypted, this.oneToOne);
}

final currentNotificationModeProvider =
    FutureProvider.family<String, NotificationConfiguration>(
        (ref, config) async {
  final client = ref.watch(clientProvider);
  if (client == null) {
    throw 'No client';
  }
  return (await client.defaultNotificationMode(
    config.encrypted,
    config.oneToOne,
  ));
});
